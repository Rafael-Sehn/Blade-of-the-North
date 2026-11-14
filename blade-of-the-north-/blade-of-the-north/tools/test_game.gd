extends SceneTree

var results := []
func check(name: String, ok: bool) -> void:
	results.append(ok); print(("OK   " if ok else "FALHA ") + name)

func frames(n: int) -> void:
	for i in n: await physics_frame

func press(a: String) -> void:
	Input.action_press(a)
func release(a: String) -> void:
	Input.action_release(a)
func tap(a: String) -> void:
	Input.action_press(a); await frames(2); Input.action_release(a); await frames(1)

func _init() -> void:
	for a in ["move_left","move_right","jump","attack","restart"]:
		check("ação " + a, InputMap.has_action(a) and InputMap.action_get_events(a).size() > 0)
	var game: Node = load("res://game.tscn").instantiate()
	root.add_child(game)
	await frames(60)
	var p = game.get_node("Player"); var e = game.get_node("Enemy")
	check("jogador pousa no chão", p.is_on_floor())
	check("jogador acima do chão (y<600)", p.global_position.y < 600)
	check("vida inicial 5", p.health == 5)
	# mover
	var x0: float = p.global_position.x
	press("move_right"); await frames(20); release("move_right")
	check("move para a direita", p.global_position.x > x0 + 50)
	var x1: float = p.global_position.x
	press("move_left"); await frames(10); release("move_left")
	check("move para a esquerda", p.global_position.x < x1 - 20)
	# pular
	await frames(30)
	var y0: float = p.global_position.y
	await tap("jump"); await frames(12)
	check("pula", p.global_position.y < y0 - 40)
	await frames(80)
	check("volta ao chão", p.is_on_floor())
	# atravessar chão?
	check("não atravessa o chão", p.global_position.y < 600)
	# inimigo fora do raio de detecção fica parado
	var ex: float = e.global_position.x
	await frames(60)
	check("inimigo parado fora do raio", absf(e.global_position.x - ex) < 1.0)
	# aproximar-se para entrar no raio de detecção
	press("move_right"); await frames(70); release("move_right")
	await frames(240)
	check("inimigo se aproximou", absf(e.global_position.x - p.global_position.x) < 120)
	check("inimigo causou dano ao jogador", p.health < 5)
	# atacar inimigo: virar para ele
	var hp_e: int = e.health
	var dir: float = signf(e.global_position.x - p.global_position.x)
	press("move_right" if dir > 0 else "move_left"); await frames(3); release("move_right"); release("move_left")
	await tap("attack"); await frames(15)
	check("ataque causa dano ao inimigo", e.health == hp_e - 1)
	# um golpe = um dano
	await frames(30)
	check("dano só uma vez por golpe", e.health == hp_e - 1)
	# matar inimigo -> vitória
	for i in 6:
		if not is_instance_valid(e): break
		dir = signf(e.global_position.x - p.global_position.x)
		press("move_right" if dir > 0 else "move_left"); await frames(2); release("move_right"); release("move_left")
		await tap("attack"); await frames(25)
	check("vitória exibida", game._finished and game.get_node("HUD/ResultPanel").visible)
	check("texto de vitória", game.get_node("HUD/ResultPanel/Box/ResultLabel").text == "VITÓRIA" and game.get_node("HUD/ResultPanel").visible)
	game.queue_free(); await frames(3)
	# derrota
	var g2: Node = load("res://game.tscn").instantiate()
	root.add_child(g2); await frames(5)
	var p2 = g2.get_node("Player")
	for i in 8:
		p2.take_damage(1, 0.0); await frames(60)
	check("derrota: vida 0", p2.health == 0)
	check("derrota exibida", g2._finished and g2.get_node("HUD/ResultPanel/Box/ResultLabel").text == "DERROTA")
	g2.queue_free(); await frames(3)
	# menu
	var m: Node = load("res://ui/menu.tscn").instantiate()
	root.add_child(m); await frames(2)
	check("menu carrega com botão Iniciar", m.get_node("Box/StartButton") != null)
	print("RESULTADO: %d/%d" % [results.count(true), results.size()])
	quit(0 if not results.has(false) else 1)
