class_name VillagerLines
extends RefCounted
## Small-talk for villagers. Line ids: vil_<m|f>_<topic>_<n> in data/dialogue.json (with _uk
## versions); voiced by a male and a female voice.

const COUNTS := {"hello": 6, "morning": 3, "evening": 3, "sleepy": 2, "scared": 3}

const TEXT := {
	"hello": [
		["Stay safe out there. The dead don't sleep anymore.", "Бережи себе. Мерці більше не сплять."],
		["The guards say the blight is spreading. I hope they're wrong.", "Вартові кажуть, що пошесть шириться. Сподіваюся, вони помиляються."],
		["Need something? The trader by the square buys and sells everything.", "Щось треба? Торговець біля площі купує і продає все."],
		["Don't go into the woods after dark. Please.", "Не ходи в ліс після заходу сонця. Прошу."],
		["Every night we hear them scratching at the walls.", "Щоночі ми чуємо, як вони шкрябають стіни."],
		["Thank you for helping us. Not many would.", "Дякую, що допомагаєш нам. Мало хто на таке зважиться."],
	],
	"morning": [
		["Good morning. Another night survived.", "Доброго ранку. Ще одну ніч пережили."],
		["Morning! Lots of work today.", "Доброго ранку! Сьогодні багато роботи."],
		["The sun is up. The monsters hide now, for a while.", "Сонце зійшло. Чудовиська ховаються, але ненадовго."],
	],
	"evening": [
		["It's getting dark. I'm heading home soon.", "Темніє. Скоро піду додому."],
		["Good evening. Lock your door tonight.", "Добрий вечір. Замкни сьогодні двері."],
		["Long day. Time for supper.", "Довгий день. Час вечеряти."],
	],
	"sleepy": [
		["Zzz... Hm? Leave me alone, it's the middle of the night!", "Хррр... Га? Дай поспати, зараз же ніч!"],
		["What are you doing in my house? Go away, I'm sleeping!", "Що ти робиш у моїй хаті? Іди геть, я сплю!"],
	],
	"scared": [
		["Help! Guards! Guards!", "Рятуйте! Варта! Варта!"],
		["Stop! Please, don't hurt me!", "Стій! Будь ласка, не чіпай мене!"],
		["Murderer! Somebody help!", "Вбивця! Хтось, допоможіть!"],
	],
}

const MALE_NAMES := ["Taras", "Bohdan", "Ostap", "Mykola", "Ivan", "Petro", "Hryts", "Stepan", "Andriy", "Vasyl", "Oleh", "Danylo"]
const FEMALE_NAMES := ["Oksana", "Solomiia", "Kateryna", "Marta", "Halyna", "Olena", "Iryna", "Nadiia", "Daryna", "Lesia", "Khrystia"]


static func pick(gender: String, topic: String) -> String:
	return "vil_%s_%s_%d" % [gender, topic, randi_range(1, COUNTS[topic])]
