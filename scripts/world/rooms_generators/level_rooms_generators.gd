extends Node2D


const ROOM_DATA_PATH = "res://data/room_data.json"
const ROOM_SIZE: int = 27 * 32

enum LEVEL_SCENE {
	goblin,
	ogre,
	vampire
}

var scene: LEVEL_SCENE
var storey_data: Dictionary = Global.storey_data
var storey_level: int = Global.storey_level
var room_data: Dictionary = FileFunction.json_as_dictionary(ROOM_DATA_PATH)
var room_group_data: Array = []
var branch_way_group_data: Array = []
var room_enemy_group_data: Array = []
var max_room_amount: int
var main_way_room_amount: int
var branch_way_room_amount: int
var branch_way_amount: int
var room_amount: int = 0
var room_number: int = 0
var sum_of_enemy_price: int = 0

@onready var player: Player = $"../Player"


func _ready() -> void:
	compute_sum_of_enemy_price()
	rooms_generator()
	room_enemy_group_data_generator()


func compute_sum_of_enemy_price():
	GlobalPlayerState.compute_player_wealth()
	
	var cp = Global.classes_data.property.get(GlobalPlayerState.player_classes).price
	var pw = GlobalPlayerState.player_wealth
	var deviation = cp / pw
	sum_of_enemy_price = \
	#randi_range(
		#pw + pw * deviation,
		#pw - pw * deviation
	#)
	pw
	
	print("/[compute_sum_of_enemy_price] => ", sum_of_enemy_price, ", deviation: ", deviation)

func rooms_generator():
	print("[rooms_generator]")
	
	var storey_scene: String = storey_data.get(str(storey_level)).scene
	var room: Node = null
	var room_class: String = ""
	var player_spawn_position: Vector2 = Vector2()
	
	if !storey_data.get(str(storey_level)).storey_class == "boss_room":
		room_group_data = []
		room_amount = 0
		room_number = 0
		
		var branch_room_amount_group: Array
		var not_empty_room: Array
		var room_door_direction: Array
		var room_position: Vector2
		var room_direction: Vector2
		var branch_direction: Vector2
		var old_room_door_direction: Array
		var old_room_position: Vector2
		var old_room_data: Dictionary
		var repeat: bool = false
		
		#room generator
		max_room_amount = storey_data.get(str(storey_level)).room_amount
		if room_amount < max_room_amount:
			#main way
			print("[main_way]")
			main_way_room_amount = storey_data.get(str(storey_level)).main_way_room_amount
			while room_amount < main_way_room_amount:
				print("[room_generator]")
				
				if room_amount == 0:
					room_class = "from"
				elif room_amount < main_way_room_amount - 1:
					room_class = "fight"
				else:
					room_class = "end"
				
				if room_class != "from":
					room_direction = old_room_door_direction.back()
					room_position += room_direction
					
					if room_position in not_empty_room:
						not_empty_room.pop_back()
						room_group_data.pop_back()
						old_room_data = room_group_data.back()
						old_room_door_direction = old_room_data.door_direction
						room_class = old_room_data.class
						room_position = old_room_data.position
						room_direction = old_room_data.direction
						room_door_direction = old_room_data.door_direction
						room_amount -= 1
						repeat = true
						
						print("break(repeat.pos) => index: " + str(room_group_data.size()) + ", old_room_data: ", old_room_data)
						print()
					else:
						repeat = false
						room_door_direction = []
						
						while room_door_direction.size() < 2:
							while room_door_direction.size() < 1:
								var v
								match old_room_door_direction.back():
									Vector2(1, 0): v = Vector2(-1, 0)
									Vector2(-1, 0): v = Vector2(1, 0)
									Vector2(0, 1): v = Vector2(0, -1)
									Vector2(0, -1): v = Vector2(0, 1)
								room_door_direction.push_back(v)
							
							if room_class == "end":
								break
							else:
								var a = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
								var x = a[randi() % a.size()]
								
								if room_door_direction.has(x):
									print("break => repeat.dir")
									print()
									
									repeat = true
								else:
									repeat = false
									room_door_direction.push_back(x)
				else:
					room_position = Vector2(0, 0)
					
					var a = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
					var v = a[randi() % a.size()]
					room_door_direction.push_back(v)
				
				if !repeat:
					room_amount += 1
					old_room_position = room_position
					old_room_door_direction = room_door_direction
					not_empty_room.push_back(room_position)
					
					var data_group: Dictionary = {
						"class" = room_class,
						"position" = room_position,
						"direction" = room_direction,
						"door_direction" = room_door_direction,
					}
					room_group_data.push_back(data_group)
					print("index: ", room_group_data.size())
					print("room_class: ", room_class)
					print("room_position:  ", room_position)
					print("not_emoty_room: ", not_empty_room)
					print("room_direction:  ", room_direction)
					print("room_door_direction:  ", room_door_direction)
					#print("room_amount: ", room_amount)
					print("/[room_generator]")
					print()
			print("/[main_way]")
			print()
			
			#branch way
			if room_amount < max_room_amount:
				print("[branch_way]")
				branch_way_room_amount = storey_data.get(str(storey_level)).branch_way_room_amount
				branch_way_amount = (
					(max_room_amount - main_way_room_amount) / branch_way_room_amount + 1
					if (max_room_amount - main_way_room_amount) % branch_way_room_amount != 0 else
					(max_room_amount - main_way_room_amount) / branch_way_room_amount
				)
				var remain_room_amount = max_room_amount - main_way_room_amount
				while branch_room_amount_group.size() < branch_way_amount:
					var v = (branch_way_room_amount if remain_room_amount >= branch_way_room_amount else remain_room_amount)
					remain_room_amount -= v
					branch_room_amount_group.push_back(v)
				
				#way
				var branch_data: Array
				var current_room_amount: int = 0
				while branch_way_group_data.size() < branch_way_amount:
					print("[way_generator]")
					
					var need_room_amount = branch_room_amount_group[branch_way_group_data.size()]
					var root_room_index = (randi() % (room_group_data.size() - 2)) + 1
					var root_room_data: Dictionary = room_group_data[root_room_index]
					if root_room_data.door_direction.size() >= 4:
						continue
					
					var empty_direction: Array = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
					var not_empty_direction: Array = root_room_data.door_direction
					for pos in not_empty_room:
						#print("pos: ", pos)
						for dir in empty_direction:
							#print(true if not_empty_room[root_room_index] + dir == pos else false)
							if not_empty_room[root_room_index] + dir == pos:
								empty_direction.erase(dir)
								#print("empty_direction - ", dir)
								break
					#print("empty_direction => ", empty_direction)
					if empty_direction.is_empty():
						return recurrence()
					
					room_position = root_room_data.position
					old_room_position = root_room_data.position
					old_room_door_direction = root_room_data.door_direction
					branch_direction = empty_direction[randi() % empty_direction.size()]
					room_direction = branch_direction
					root_room_data.door_direction.insert(root_room_data.door_direction.size() - 1, branch_direction)
					
					print("/[change_room_group_data](index: " + str(root_room_index + 1) + ") => position: " + str(root_room_data.position) + ", door_direction: " + str(root_room_data.door_direction))
					#room
					while current_room_amount < need_room_amount:
						print("[room_generator]")
						
						room_class = ("fight" if current_room_amount < need_room_amount - 1 else "end")
						room_direction = (branch_direction if current_room_amount == 0 else old_room_door_direction.back())
						room_position += room_direction
						
						if room_position in not_empty_room:
							print("break => repeat.pos")
							print()
							
							current_room_amount = (current_room_amount - 1 if current_room_amount != 0 else 0)
							room_amount = (room_amount - 1 if current_room_amount != 0 else 0)
							if !branch_data.is_empty(): not_empty_room.pop_back()
							branch_data.pop_back()
							old_room_data = (branch_data.back() if !branch_data.is_empty() else root_room_data)
							old_room_door_direction = old_room_data.door_direction
							room_class = old_room_data.class
							room_position = old_room_data.position
							room_direction = old_room_data.direction
							room_door_direction = old_room_data.door_direction
							repeat = true
						else:
							repeat = false
							room_door_direction = []
							
							while room_door_direction.size() < 2:
								if room_door_direction.size() < 1:
									var v
									var x = (
										branch_direction
										if current_room_amount == 0 else
										old_room_door_direction.back())
									match x:
										Vector2(1, 0): v = Vector2(-1, 0)
										Vector2(-1, 0): v = Vector2(1, 0)
										Vector2(0, 1): v = Vector2(0, -1)
										Vector2(0, -1): v = Vector2(0, 1)
									room_door_direction.push_back(v)
								
								if room_class == "end":
									break
								else:
									var a = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
									var x = a[randi() % a.size()]
									
									if room_door_direction.has(x):
										#print("[room_door_direction] ", room_door_direction)
										print("break => repeat.dir")
										print()
										
										repeat = true
									else:
										repeat = false
										room_door_direction.push_back(x)
						
						if !repeat:
							room_amount += 1
							current_room_amount += 1
							old_room_position = room_position
							old_room_door_direction = room_door_direction
							not_empty_room.push_back(room_position)
							
							var data_group: Dictionary = {
								"class" = room_class,
								"position" = room_position,
								"direction" = room_direction,
								"door_direction" = room_door_direction,
								"branch_root_index" = root_room_index
							}
							branch_data.push_back(data_group)
							print("index: ", room_group_data.size() + branch_data.size())
							print("room_class: ", room_class)
							print("room_position:  ", room_position)
							print("not_emoty_room: ", not_empty_room)
							print("room_direction:  ", room_direction)
							print("room_door_direction:  ", room_door_direction)
							#print("room_amount: ", room_amount)
							print("/[room_generator]")
							print()
					branch_way_group_data.push_back(branch_data)
					current_room_amount = 0
					print("/[way_generator]")
				for way in branch_way_group_data:
					for i in way:
						room_group_data.push_back(i)
				print("/[branch_way]")
				print()
		
		#room spawn
		#if !(room_amount < max_room_amount):
			var save_room_data = room_group_data.duplicate()
			while room_amount > 1 && room_number != max_room_amount:
				if save_room_data.is_empty():
					return recurrence()
				else:
					print("[room_spawn]")
					
					if room_number == 1:
						player_spawn_position = room.player_spawn_position
						GlobalPlayerState.player.position = player_spawn_position
					
					var data = save_room_data.pop_front()
					room_class = data.class
					room_position = data.position
					room_direction = data.direction
					room_door_direction = data.door_direction
					
					var compute_key = func(key: Array) -> String:
						var v: String
						var a = key.duplicate()
						if a.has(Vector2(-1, 0)):
							v += "left"
							a.erase(Vector2(-1, 0))
						if a.has(Vector2(1, 0)):
							v += ("right" if a.size() >= key.size() else ", right")
							a.erase(Vector2(1, 0))
						if a.has(Vector2(0, -1)):
							v += ("up" if a.size() >= key.size() else ", up")
							a.erase(Vector2(0, -1))
						if a.has(Vector2(0, 1)):
							v += ("down" if a.size() >= key.size() else ", down")
							a.erase(Vector2(0, 1))
						v = v.insert(0, "[")
						v = v.insert(v.length(), "]")
						return v
					var key = compute_key.call(room_door_direction)
					var path = FileFunction.get_file_list(room_data.scene.get(storey_scene).get(room_class).get(key))
					room = load(path.get(path.keys()[randi() % path.size()])).instantiate()
					room.position.x = room_position.x * ROOM_SIZE
					room.position.y = room_position.y * ROOM_SIZE
					room_number += 1
					add_child(room)
					
					print("room_number: ", room_number)
					print("room_class: ", room_class)
					print("room_position: ", room_position)
					print("dir_door: ", key)
					print("/[room_spawn]")
					print()
			
	else:
		print("[room_spawn]")
		
		var range = room_data.scene.get(storey_scene).boss.values()
		room = load(range[randi() % range.size()]).instantiate()
		add_child(room)
		
		player_spawn_position = room.player_spawn_position
		GlobalPlayerState.player.position = player_spawn_position
		
		print("/[room_spawn]")
		print()
	print("/[room_group_generator]")

func recurrence():
	print("Some years ago, I engaged passage from Charleston, S. C, to the city of New York, in the fine packet-ship 'Independence,' Captain Hardy. We were to sail on the fifteenth of the month (June), weather permitting; and on the fourteenth, I went on board to arrange some matters in my stateroom.I found that we were to have a great many passengers, including a more than usual number of ladies. On the list were several of my acquaintances, and among other names, I was rejoiced to see that of Mr. Cornelius Wyatt, a young artist, for whom I entertained feelings of warm friendship. He had been with me a fellow-student at C—— University, where we were very much together. He had the ordinary temperament of genius, and was a compound of misanthropy, sensibility, and enthusiasm. To these qualities he united the warmest and truest heart which ever beat in a human bosom.I observed that his name was carded upon THREE state-rooms; and, upon again referring to the list of passengers, I found that he had engaged passage for himself, wife, and two sisters—his own. The state-rooms were sufficiently roomy, and each had two berths, one above the other. These berths, to be sure, were so exceedingly narrow as to be insufficient for more than one person; still, I could not comprehend why there were THREE staterooms for these four persons. I was, just at that epoch, in one of those moody frames of mind which make a man abnormally inquisitive about trifles: and I confess, with shame, that I busied myself in a variety of ill- bred and preposterous conjectures about this matter of the supernumerary stateroom. It was no business of mine, to be sure, but with none the less pertinacity did I occupy myself in attempts to resolve the enigma. At last I reached a conclusion which wrought in me great wonder why I had not arrived at it before. 'It is a servant of course,' I said; 'what a fool I am, not sooner to have thought of so obvious a solution!' And then I again repaired to the list—but here I saw distinctly that NO servant was to come with the party, although, in fact, it had been the original design to bring one—for the words 'and servant' had been first written and then over-scored. 'Oh, extra baggage, to be sure,' I now said to myself—'something he wishes not to be put in the hold—something to be kept under his own eye—ah, I have it—a painting or so—and this is what he has been bargaining about with Nicolino, the Italian Jew.' This idea satisfied me, and I dismissed my curiosity for the nonce.Wyatt's two sisters I knew very well, and most amiable and clever girls they were. His wife he had newly married, and I had never yet seen her. He had often talked about her in my presence, however, and in his usual style of enthusiasm. He described her as of surpassing beauty, wit, and accomplishment. I was, therefore, quite anxious to make her acquaintance.On the day in which I visited the ship (the fourteenth), Wyatt and party were also to visit it—so the captain informed me—and I waited on board an hour longer than I had designed, in hope of being presented to the bride, but then an apology came. 'Mrs. W. was a little indisposed, and would decline coming on board until to-morrow, at the hour of sailing.'The morrow having arrived, I was going from my hotel to the wharf, when Captain Hardy met me and said that, 'owing to circumstances' (a stupid but convenient phrase), 'he rather thought the 'Independence' would not sail for a day or two, and that when all was ready, he would send up and let me know.' This I thought strange, for there was a stiff southerly breeze; but as 'the circumstances' were not forthcoming, although I pumped for them with much perseverance, I had nothing to do but to return home and digest my impatience at leisure.I did not receive the expected message from the captain for nearly a week. It came at length, however, and I immediately went on board. The ship was crowded with passengers, and every thing was in the bustle attendant upon making sail. Wyatt's party arrived in about ten minutes after myself. There were the two sisters, the bride, and the artist—the latter in one of his customary fits of moody misanthropy. I was too well used to these, however, to pay them any special attention. He did not even introduce me to his wife;—this courtesy devolving, per force, upon his sister Marian—a very sweet and intelligent girl, who, in a few hurried words, made us acquainted.Mrs. Wyatt had been closely veiled; and when she raised her veil, in acknowledging my bow, I confess that I was very profoundly astonished. I should have been much more so, however, had not long experience advised me not to trust, with too implicit a reliance, the enthusiastic descriptions of my friend, the artist, when indulging in comments upon the loveliness of woman. When beauty was the theme, I well knew with what facility he soared into the regions of the purely ideal.The truth is, I could not help regarding Mrs. Wyatt as a decidedly plain-looking woman. If not positively ugly, she was not, I think, very far from it. She was dressed, however, in exquisite taste—and then I had no doubt that she had captivated my friend's heart by the more enduring graces of the intellect and soul. She said very few words, and passed at once into her state-room with Mr. W.My old inquisitiveness now returned. There was NO servant—THAT was a settled point. I looked, therefore, for the extra baggage. After some delay, a cart arrived at the wharf, with an oblong pine box, which was every thing that seemed to be expected. Immediately upon its arrival we made sail, and in a short time were safely over the bar and standing out to sea.The box in question was, as I say, oblong. It was about six feet in length by two and a half in breadth; I observed it attentively, and like to be precise. Now this shape was PECULIAR; and no sooner had I seen it, than I took credit to myself for the accuracy of my guessing. I had reached the conclusion, it will be remembered, that the extra baggage of my friend, the artist, would prove to be pictures, or at least a picture; for I knew he had been for several weeks in conference with Nicolino:—and now here was a box, which, from its shape, COULD possibly contain nothing in the world but a copy of Leonardo's 'Last Supper;' and a copy of this very 'Last Supper,' done by Rubini the younger, at Florence, I had known, for some time, to be in the possession of Nicolino. This point, therefore, I considered as sufficiently settled. I chuckled excessively when I thought of my acumen. It was the first time I had ever known Wyatt to keep from me any of his artistical secrets; but here he evidently intended to steal a march upon me, and smuggle a fine picture to New York, under my very nose; expecting me to know nothing of the matter. I resolved to quiz him WELL, now and hereafter.One thing, however, annoyed me not a little. The box did NOT go into the extra stateroom. It was deposited in Wyatt's own; and there, too, it remained, occupying very nearly the whole of the floor—no doubt to the exceeding discomfort of the artist and his wife;—this the more especially as the tar or paint with which it was lettered in sprawling capitals, emitted a strong, disagreeable, and, to my fancy, a peculiarly disgusting odor. On the lid were painted the words—'Mrs. Adelaide Curtis, Albany, New York. Charge of Cornelius Wyatt, Esq. This side up. To be handled with care.'Now, I was aware that Mrs. Adelaide Curtis, of Albany, was the artist's wife's mother,—but then I looked upon the whole address as a mystification, intended especially for myself. I made up my mind, of course, that the box and contents would never get farther north than the studio of my misanthropic friend, in Chambers Street, New York.For the first three or four days we had fine weather, although the wind was dead ahead; having chopped round to the northward, immediately upon our losing sight of the coast. The passengers were, consequently, in high spirits and disposed to be social. I MUST except, however, Wyatt and his sisters, who behaved stiffly, and, I could not help thinking, uncourteously to the rest of the party. Wyatt's conduct I did not so much regard. He was gloomy, even beyond his usual habit—in fact he was MOROSE—but in him I was prepared for eccentricity. For the sisters, however, I could make no excuse. They secluded themselves in their staterooms during the greater part of the passage, and absolutely refused, although I repeatedly urged them, to hold communication with any person on board.Mrs. Wyatt herself was far more agreeable. That is to say, she was CHATTY; and to be chatty is no slight recommendation at sea. She became EXCESSIVELY intimate with most of the ladies; and, to my profound astonishment, evinced no equivocal disposition to coquet with the men. She amused us all very much. I say 'amused'—and scarcely know how to explain myself. The truth is, I soon found that Mrs. W. was far oftener laughed AT than WITH. The gentlemen said little about her; but the ladies, in a little while, pronounced her 'a good-hearted thing, rather indifferent looking, totally uneducated, and decidedly vulgar.' The great wonder was, how Wyatt had been entrapped into such a match. Wealth was the general solution—but this I knew to be no solution at all; for Wyatt had told me that she neither brought him a dollar nor had any expectations from any source whatever. 'He had married,' he said, 'for love, and for love only; and his bride was far more than worthy of his love.' When I thought of these expressions, on the part of my friend, I confess that I felt indescribably puzzled. Could it be possible that he was taking leave of his senses? What else could I think? HE, so refined, so intellectual, so fastidious, with so exquisite a perception of the faulty, and so keen an appreciation of the beautiful! To be sure, the lady seemed especially fond of HIM—particularly so in his absence—when she made herself ridiculous by frequent quotations of what had been said by her 'beloved husband, Mr. Wyatt.' The word 'husband' seemed forever—to use one of her own delicate expressions—forever 'on the tip of her tongue.' In the meantime, it was observed by all on board, that he avoided HER in the most pointed manner, and, for the most part, shut himself up alone in his state-room, where, in fact, he might have been said to live altogether, leaving his wife at full liberty to amuse herself as she thought best, in the public society of the main cabin.My conclusion, from what I saw and heard, was, that, the artist, by some unaccountable freak of fate, or perhaps in some fit of enthusiastic and fanciful passion, had been induced to unite himself with a person altogether beneath him, and that the natural result, entire and speedy disgust, had ensued. I pitied him from the bottom of my heart—but could not, for that reason, quite forgive his incommunicativeness in the matter of the 'Last Supper.' For this I resolved to have my revenge.One day he came upon deck, and, taking his arm as had been my wont, I sauntered with him backward and forward. His gloom, however (which I considered quite natural under the circumstances), seemed entirely unabated. He said little, and that moodily, and with evident effort. I ventured a jest or two, and he made a sickening attempt at a smile. Poor fellow!—as I thought of HIS WIFE, I wondered that he could have heart to put on even the semblance of mirth. At last I ventured a home thrust. I determined to commence a series of covert insinuations, or innuendoes, about the oblong box—just to let him perceive, gradually, that I was NOT altogether the butt, or victim, of his little bit of pleasant mystification. My first observation was by way of opening a masked battery. I said something about the 'peculiar shape of THAT box—,'and, as I spoke the words, I smiled knowingly, winked, and touched him gently with my forefinger in the ribs.The manner in which Wyatt received this harmless pleasantry convinced me, at once, that he was mad. At first he stared at me as if he found it impossible to comprehend the witticism of my remark; but as its point seemed slowly to make its way into his brain, his eyes, in the same proportion, seemed protruding from their sockets. Then he grew very red—then hideously pale—then, as if highly amused with what I had insinuated, he began a loud and boisterous laugh, which, to my astonishment, he kept up, with gradually increasing vigor, for ten minutes or more. In conclusion, he fell flat and heavily upon the deck. When I ran to uplift him, to all appearance he was DEAD.I called assistance, and, with much difficulty, we brought him to himself. Upon reviving he spoke incoherently for some time. At length we bled him and put him to bed. The next morning he was quite recovered, so far as regarded his mere bodily health. Of his mind I say nothing, of course. I avoided him during the rest of the passage, by advice of the captain, who seemed to coincide with me altogether in my views of his insanity, but cautioned me to say nothing on this head to any person on board.Several circumstances occurred immediately after this fit of Wyatt which contributed to heighten the curiosity with which I was already possessed. Among other things, this: I had been nervous—drank too much strong green tea, and slept ill at night—in fact, for two nights I could not be properly said to sleep at all. Now, my state-room opened into the main cabin, or dining-room, as did those of all the single men on board. Wyatt's three rooms were in the after-cabin, which was separated from the main one by a slight sliding door, never locked even at night. As we were almost constantly on a wind, and the breeze was not a little stiff, the ship heeled to leeward very considerably; and whenever her starboard side was to leeward, the sliding door between the cabins slid open, and so remained, nobody taking the trouble to get up and shut it. But my berth was in such a position, that when my own state-room door was open, as well as the sliding door in question (and my own door was ALWAYS open on account of the heat,) I could see into the after-cabin quite distinctly, and just at that portion of it, too, where were situated the state-rooms of Mr. Wyatt. Well, during two nights (NOT consecutive) while I lay awake, I clearly saw Mrs. W., about eleven o'clock upon each night, steal cautiously from the state-room of Mr. W., and enter the extra room, where she remained until daybreak, when she was called by her husband and went back. That they were virtually separated was clear. They had separate apartments—no doubt in contemplation of a more permanent divorce; and here, after all I thought was the mystery of the extra stateroom.There was another circumstance, too, which interested me much. During the two wakeful nights in question, and immediately after the disappearance of Mrs. Wyatt into the extra stateroom, I was attracted by certain singular cautious, subdued noises in that of her husband. After listening to them for some time, with thoughtful attention, I at length succeeded perfectly in translating their import. They were sounds occasioned by the artist in prying open the oblong box, by means of a chisel and mallet—the latter being apparently muffled, or deadened, by some soft woollen or cotton substance in which its head was enveloped.In this manner I fancied I could distinguish the precise moment when he fairly disengaged the lid—also, that I could determine when he removed it altogether, and when he deposited it upon the lower berth in his room; this latter point I knew, for example, by certain slight taps which the lid made in striking against the wooden edges of the berth, as he endeavored to lay it down VERY gently—there being no room for it on the floor. After this there was a dead stillness, and I heard nothing more, upon either occasion, until nearly daybreak; unless, perhaps, I may mention a low sobbing, or murmuring sound, so very much suppressed as to be nearly inaudible—if, indeed, the whole of this latter noise were not rather produced by my own imagination. I say it seemed to RESEMBLE sobbing or sighing—but, of course, it could not have been either. I rather think it was a ringing in my own ears. Mr. Wyatt, no doubt, according to custom, was merely giving the rein to one of his hobbies—indulging in one of his fits of artistic enthusiasm. He had opened his oblong box, in order to feast his eyes on the pictorial treasure within. There was nothing in this, however, to make him SOB. I repeat, therefore, that it must have been simply a freak of my own fancy, distempered by good Captain Hardy's green tea. just before dawn, on each of the two nights of which I speak, I distinctly heard Mr. Wyatt replace the lid upon the oblong box, and force the nails into their old places by means of the muffled mallet. Having done this, he issued from his state- room, fully dressed, and proceeded to call Mrs. W. from hers.We had been at sea seven days, and were now off Cape Hatteras, when there came a tremendously heavy blow from the southwest. We were, in a measure, prepared for it, however, as the weather had been holding out threats for some time. Every thing was made snug, alow and aloft; and as the wind steadily freshened, we lay to, at length, under spanker and foretopsail, both double-reefed.In this trim we rode safely enough for forty-eight hours—the ship proving herself an excellent sea-boat in many respects, and shipping no water of any consequence. At the end of this period, however, the gale had freshened into a hurricane, and our after—sail split into ribbons, bringing us so much in the trough of the water that we shipped several prodigious seas, one immediately after the other. By this accident we lost three men overboard with the caboose, and nearly the whole of the larboard bulwarks. Scarcely had we recovered our senses, before the foretopsail went into shreds, when we got up a storm staysail and with this did pretty well for some hours, the ship heading the sea much more steadily than before.The gale still held on, however, and we saw no signs of its abating. The rigging was found to be ill-fitted, and greatly strained; and on the third day of the blow, about five in the afternoon, our mizzen-mast, in a heavy lurch to windward, went by the board. For an hour or more, we tried in vain to get rid of it, on account of the prodigious rolling of the ship; and, before we had succeeded, the carpenter came aft and announced four feet of water in the hold. To add to our dilemma, we found the pumps choked and nearly useless.All was now confusion and despair—but an effort was made to lighten the ship by throwing overboard as much of her cargo as could be reached, and by cutting away the two masts that remained. This we at last accomplished—but we were still unable to do any thing at the pumps; and, in the meantime, the leak gained on us very fast.At sundown, the gale had sensibly diminished in violence, and as the sea went down with it, we still entertained faint hopes of saving ourselves in the boats. At eight P. M., the clouds broke away to windward, and we had the advantage of a full moon—a piece of good fortune which served wonderfully to cheer our drooping spirits.After incredible labor we succeeded, at length, in getting the longboat over the side without material accident, and into this we crowded the whole of the crew and most of the passengers. This party made off immediately, and, after undergoing much suffering, finally arrived, in safety, at Ocracoke Inlet, on the third day after the wreck.Fourteen passengers, with the captain, remained on board, resolving to trust their fortunes to the jolly-boat at the stern. We lowered it without difficulty, although it was only by a miracle that we prevented it from swamping as it touched the water. It contained, when afloat, the captain and his wife, Mr. Wyatt and party, a Mexican officer, wife, four children, and myself, with a negro valet.We had no room, of course, for any thing except a few positively necessary instruments, some provisions, and the clothes upon our backs. No one had thought of even attempting to save any thing more. What must have been the astonishment of all, then, when having proceeded a few fathoms from the ship, Mr. Wyatt stood up in the stern-sheets, and coolly demanded of Captain Hardy that the boat should be put back for the purpose of taking in his oblong box!'Sit down, Mr. Wyatt,' replied the captain, somewhat sternly, 'you will capsize us if you do not sit quite still. Our gunwhale is almost in the water now.''The box!' vociferated Mr. Wyatt, still standing—'the box, I say! Captain Hardy, you cannot, you will not refuse me. Its weight will be but a trifle—it is nothing—mere nothing. By the mother who bore you—for the love of Heaven—by your hope of salvation, I implore you to put back for the box!'The captain, for a moment, seemed touched by the earnest appeal of the artist, but he regained his stern composure, and merely said:'Mr. Wyatt, you are mad. I cannot listen to you. Sit down, I say, or you will swamp the boat. Stay—hold him—seize him!—he is about to spring overboard! There—I knew it—he is over!'As the captain said this, Mr. Wyatt, in fact, sprang from the boat, and, as we were yet in the lee of the wreck, succeeded, by almost superhuman exertion, in getting hold of a rope which hung from the fore-chains. In another moment he was on board, and rushing frantically down into the cabin.In the meantime, we had been swept astern of the ship, and being quite out of her lee, were at the mercy of the tremendous sea which was still running. We made a determined effort to put back, but our little boat was like a feather in the breath of the tempest. We saw at a glance that the doom of the unfortunate artist was sealed.As our distance from the wreck rapidly increased, the madman (for as such only could we regard him) was seen to emerge from the companion—way, up which by dint of strength that appeared gigantic, he dragged, bodily, the oblong box. While we gazed in the extremity of astonishment, he passed, rapidly, several turns of a three-inch rope, first around the box and then around his body. In another instant both body and box were in the sea—disappearing suddenly, at once and forever.We lingered awhile sadly upon our oars, with our eyes riveted upon the spot. At length we pulled away. The silence remained unbroken for an hour. Finally, I hazarded a remark.'Did you observe, captain, how suddenly they sank? Was not that an exceedingly singular thing? I confess that I entertained some feeble hope of his final deliverance, when I saw him lash himself to the box, and commit himself to the sea.''They sank as a matter of course,' replied the captain, 'and that like a shot. They will soon rise again, however—BUT NOT TILL THE SALT MELTS.''The salt!' I ejaculated.'Hush!' said the captain, pointing to the wife and sisters of the deceased. 'We must talk of these things at some more appropriate time.'We suffered much, and made a narrow escape, but fortune befriended us, as well as our mates in the long-boat. We landed, in fine, more dead than alive, after four days of intense distress, upon the beach opposite Roanoke Island. We remained here a week, were not ill-treated by the wreckers, and at length obtained a passage to New York.About a month after the loss of the 'Independence,' I happened to meet Captain Hardy in Broadway. Our conversation turned, naturally, upon the disaster, and especially upon the sad fate of poor Wyatt. I thus learned the following particulars.The artist had engaged passage for himself, wife, two sisters and a servant. His wife was, indeed, as she had been represented, a most lovely, and most accomplished woman. On the morning of the fourteenth of June (the day in which I first visited the ship), the lady suddenly sickened and died. The young husband was frantic with grief—but circumstances imperatively forbade the deferring his voyage to New York. It was necessary to take to her mother the corpse of his adored wife, and, on the other hand, the universal prejudice which would prevent his doing so openly was well known. Nine-tenths of the passengers would have abandoned the ship rather than take passage with a dead body.In this dilemma, Captain Hardy arranged that the corpse, being first partially embalmed, and packed, with a large quantity of salt, in a box of suitable dimensions, should be conveyed on board as merchandise. Nothing was to be said of the lady's decease; and, as it was well understood that Mr. Wyatt had engaged passage for his wife, it became necessary that some person should personate her during the voyage. This the deceased lady's-maid was easily prevailed on to do. The extra state-room, originally engaged for this girl during her mistress' life, was now merely retained. In this state-room the pseudo-wife, slept, of course, every night. In the daytime she performed, to the best of her ability, the part of her mistress—whose person, it had been carefully ascertained, was unknown to any of the passengers on board.My own mistake arose, naturally enough, through too careless, too inquisitive, and too impulsive a temperament. But of late, it is a rare thing that I sleep soundly at night. There is a countenance which haunts me, turn as I will. There is an hysterical laugh which will forever ring within my ears.")
	for child in get_children():
		remove_child(child)
	rooms_generator()
#摆了，重跑吧

func room_enemy_group_data_generator():
	print("[room_enemy_group_generator]")
	
	var group_fight_room_amount: int = max_room_amount - 2
	while room_enemy_group_data.size() < group_fight_room_amount:
		room_enemy_group_data.push_back(enemy_group_generator())
	
	print("/[room_enemy_group_generator] => room_enemy_group_data: ", room_enemy_group_data)
	print()

func enemy_group_generator():
	var enemy_group_data: Array
	var group_fight_room_amount: int = max_room_amount - 2
	var enemy_group_price = sum_of_enemy_price / group_fight_room_amount as int
	var current_enemys_price = enemy_group_price
	
	while current_enemys_price > 0:
		var enemy: String
		var enemy_scene_file: PackedScene
		var enemy_file_list: Dictionary = FileFunction.get_file_list(Global.ENEMY_DIRECTORY)
		var enemy_data_list: Array = Global.enemy_data.keys()
		var key: String = enemy_data_list[randi() % enemy_data_list.size()]
		enemy = enemy_file_list.get(key)
		enemy_group_data.push_back(enemy)
		current_enemys_price -= Global.enemy_data.get(key).price
	
	if current_enemys_price < 0:
		enemy_group_generator()
	else:
		print("/[enemy_group_data_generator] => enemy_group_data: ", enemy_group_data)
		print()
		return enemy_group_data
