class_name TrackAI
extends RefCounted
## Local evolutionary track designer. It needs no network, API key or model file:
## a seeded genetic algorithm breeds "genomes" (one gene per course section) and
## keeps the one whose difficulty, variety and rhythm score best. The same seed and
## level always give the same course, so seeds stay shareable between players.
##
## Section kinds: straight, curve, ramp, drop, hazard, plus the two extreme ones
## added by this designer: "jump" (a real gap in the deck) and "plunge" (a very
## steep descent).
const KINDS: Array[String] = ["straight", "curve", "ramp", "drop", "hazard", "jump", "plunge"]
const LEGACY_KINDS: Array[String] = ["straight", "curve", "ramp", "drop", "hazard"]
const FREE_GENES := 6
const POPULATION := 24
const GENERATIONS := 14
const ELITE := 2
const TOURNAMENT := 3
const START_Y := 22.0
const MIN_Y := 9.0
const MAX_Y := 40.0
const SECTION_LENGTH := 68.0
const CELL := 2.0
const MIN_CELLS := 3
const MAX_CELLS := 6
## A marble that reaches the lip at this speed or faster always clears the gap.
## Cruise speed is 39 m/s; being slowed (16 m/s) or braking makes the jump fail,
## which is the tactical point of placing traps before a gap.
const DESIGN_SPEED := 22.0
## World gravity (9.8) plus the marble's 15 m/s² downforce, which stays active in the air.
const EFFECTIVE_GRAVITY := 24.8
const LANDING_MARGIN := 0.6
const MAX_LANDING_DROP := 7.0
## Each pair costs a marble 18 health on its own side; 3 pairs (54) can never decide a race on their own.
const MAX_HAZARD_PAIRS := 3
const HAZARD_FACTORS := {1: [0.5], 2: [0.32, 0.70], 3: [0.25, 0.5, 0.75]}

var best_score := 0.0

static func random_gene(rng: RandomNumberGenerator, kind: String = "", legacy: bool = false) -> Dictionary:
	if kind == "":
		var pool := LEGACY_KINDS if legacy else KINDS
		kind = pool[rng.randi_range(0, pool.size() - 1)]
	var gene := {"kind": kind, "dy": 0.0, "cells": 0, "pairs": 0}
	match kind:
		"curve":
			gene.dy = rng.randf_range(-3, 3) if not legacy else rng.randf_range(-2, 2)
			gene.pairs = 0 if legacy else rng.randi_range(0, 2)
		"ramp":
			gene.dy = rng.randf_range(7, 10) if legacy else rng.randf_range(7, 16)
		"drop":
			gene.dy = -rng.randf_range(10, 13) if legacy else -rng.randf_range(10, 14)
		"hazard":
			gene.pairs = 2 if legacy else rng.randi_range(1, 3)
		"plunge":
			gene.dy = -rng.randf_range(18, 27)
		"jump":
			gene.dy = -rng.randf_range(1, 6)
			gene.cells = rng.randi_range(MIN_CELLS, MAX_CELLS)
	return gene

## The pre-AI course layout, kept as a deterministic safety net.
static func legacy_genome(course_seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = course_seed
	var order: Array[String] = ["straight", "curve", "ramp", "drop", "hazard"]
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	order.append("curve")
	var genome: Array[Dictionary] = []
	for kind in order:
		genome.append(random_gene(rng, kind, true))
	return genome

## Height lost between the lip and the far side of a gap so that a marble moving at
## DESIGN_SPEED lands on the deck instead of the wall. Faster marbles land higher on it.
static func landing_drop(gene: Dictionary) -> float:
	if gene.kind != "jump":
		return 0.0
	var gap: float = gene.cells * CELL
	var slope := maxf(0.0, -gene.dy) * 1.5 / SECTION_LENGTH
	var time := gap / DESIGN_SPEED
	return slope * gap + 0.5 * EFFECTIVE_GRAVITY * time * time + LANDING_MARGIN

## 0 = harmless, 1 = brutal. Used by the fitness function and by the tests.
static func danger(gene: Dictionary) -> float:
	match gene.kind:
		"curve":
			return 0.10 + 0.12 * gene.pairs
		"ramp":
			return 0.10 + 0.40 * clampf((gene.dy - 7.0) / 9.0, 0.0, 1.0)
		"drop":
			return 0.20
		"plunge":
			return 0.35 + 0.65 * clampf((-gene.dy - 18.0) / 9.0, 0.0, 1.0)
		"hazard":
			return 0.25 + 0.20 * gene.pairs
		"jump":
			return 0.45 + 0.55 * float(gene.cells - MIN_CELLS) / float(MAX_CELLS - MIN_CELLS)
	return 0.0

func evaluate(genome: Array[Dictionary], level: float) -> float:
	var target := 0.25 + 0.5 * level
	var y := START_Y
	var penalty := 0.0
	var total := 0.0
	var kinds := {}
	var jumps := 0
	var slopes := 0
	var pairs := 0
	var previous: Dictionary = {}
	for gene in genome:
		var drop := landing_drop(gene)
		if drop > MAX_LANDING_DROP:
			penalty += 100.0
		y += gene.dy - drop
		if y < MIN_Y:
			penalty += 20.0 + (MIN_Y - y) * 2.0
		elif y > MAX_Y:
			penalty += 20.0 + (y - MAX_Y) * 2.0
		var value := danger(gene)
		total += value
		kinds[gene.kind] = true
		if gene.kind == "jump":
			jumps += 1
		if gene.kind in ["ramp", "drop", "plunge"]:
			slopes += 1
		pairs += gene.pairs if gene.kind in ["hazard", "curve"] else 0
		if not previous.is_empty():
			if previous.kind == gene.kind and gene.kind != "straight":
				penalty += 1.0
			# Relief after an extreme section keeps the course learnable.
			if danger(previous) > 0.8 and value > 0.8:
				penalty += 2.0
		previous = gene
	var score := -8.0 * absf(total / genome.size() - target) - penalty
	score += 0.35 * kinds.size()
	if level >= 0.4 and jumps > 0:
		score += 1.0
	if level >= 0.6 and kinds.has("plunge"):
		score += 1.0
	if jumps > 2:
		score -= 1.5 * (jumps - 2)
	if slopes == 0:
		score -= 3.0
	if pairs > MAX_HAZARD_PAIRS:
		score -= 6.0 * (pairs - MAX_HAZARD_PAIRS)
	return score

func random_genome(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var genome: Array[Dictionary] = []
	for i in range(FREE_GENES):
		genome.append(random_gene(rng))
	return genome

func _crossover(first: Array[Dictionary], second: Array[Dictionary], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var child: Array[Dictionary] = []
	for i in range(FREE_GENES):
		child.append((first[i] if rng.randf() < 0.5 else second[i]).duplicate())
	return child

func _mutate(genome: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for i in range(genome.size()):
		if rng.randf() > 0.25:
			continue
		var gene := genome[i]
		if rng.randf() < 0.4:
			genome[i] = random_gene(rng)
			continue
		match gene.kind:
			"ramp":
				gene.dy = clampf(gene.dy + rng.randf_range(-2, 2), 7, 16)
			"drop":
				gene.dy = clampf(gene.dy + rng.randf_range(-2, 2), -14, -10)
			"plunge":
				gene.dy = clampf(gene.dy + rng.randf_range(-3, 3), -27, -18)
			"curve":
				gene.dy = clampf(gene.dy + rng.randf_range(-1.5, 1.5), -3, 3)
				gene.pairs = clampi(gene.pairs + rng.randi_range(-1, 1), 0, 2)
			"hazard":
				gene.pairs = clampi(gene.pairs + rng.randi_range(-1, 1), 1, 3)
			"jump":
				gene.dy = clampf(gene.dy + rng.randf_range(-1.5, 1.5), -6, -1)
				gene.cells = clampi(gene.cells + rng.randi_range(-1, 1), MIN_CELLS, MAX_CELLS)

func _rank(population: Array, level: float) -> Array:
	var scored: Array = []
	for i in range(population.size()):
		scored.append({"genome": population[i], "score": evaluate(population[i], level), "order": i})
	scored.sort_custom(func(a, b): return a.score > b.score or (a.score == b.score and a.order < b.order))
	return scored

func _tournament(scored: Array, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var winner: Dictionary = scored[rng.randi_range(0, scored.size() - 1)]
	for i in range(TOURNAMENT - 1):
		var rival: Dictionary = scored[rng.randi_range(0, scored.size() - 1)]
		if rival.score > winner.score:
			winner = rival
	return winner.genome

## Returns the best genome found for a seed. `level` runs from 0 (gentle) to 1 (extreme).
func evolve(course_seed: int, level: float) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = course_seed + 7919
	var population: Array = []
	for i in range(POPULATION):
		population.append(random_genome(rng))
	var scored := _rank(population, level)
	for generation in range(GENERATIONS):
		var next: Array = []
		for i in range(ELITE):
			next.append(scored[i].genome)
		while next.size() < POPULATION:
			var child := _crossover(_tournament(scored, rng), _tournament(scored, rng), rng)
			_mutate(child, rng)
			next.append(child)
		scored = _rank(next, level)
	best_score = scored[0].score
	return scored[0].genome
