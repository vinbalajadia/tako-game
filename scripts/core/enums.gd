class_name Enums

enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
}

enum ECharacterAnimation {
	idle_down,
	idle_up,
	idle_left,
	idle_right,
	walk_down,
	walk_up,
	walk_left,
	walk_right,
	turn_down,
	turn_up,
	turn_left,
	turn_right,
}

enum LevelName {
	Billiards,
	Level0,
	Level01,
	Level1,
	Level11,
	Level12,
	Level2,
	Level3,
	Level31,
}

enum LevelGroup {
	SPAWNPOINTS,
	SCENETRIGGERS,
}

enum LevelId {
	Level0 = 0,
}

# From Enemy.cs — placed here alongside other enums.
enum FacingDirection {
	Down,
	Up,
	Left,
	Right,
}

enum SkillType {
	BasicArithmetic,
	Fractions,
	Algebra,
	Geometry,
	WordProblems,
	Statistics,
}
