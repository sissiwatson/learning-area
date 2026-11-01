## Interface « Avancer le temps » (0.1.6, lot 2) : section du panneau,
## confirmation (temps gagné, prix, solde après), offre unique, annulation
## sans effet, refus sans débit quand le séjour finit ou que le solde ou le
## prix changent pendant que la confirmation est ouverte, doubles touchers.
extends GutTest

const FakeClock := preload("res://tests/helpers/fake_clock.gd")
const T := SpeedupRules.Tier

var main: Node
var clock: FakeClock


func before_each() -> void:
	clock = FakeClock.new()
	GameState.clock = clock
	main = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	main.camera.setup(main.map.world_bounds(), main.map.world_bounds().get_center(), Vector2(1920, 1080))
	# Le dialogue d'ouverture démarre à la frame suivante et fermerait le panneau.
	await get_tree().process_frame
	while main.dialogue_box.visible:
		main.dialogue_box.skip()


func after_each() -> void:
	GameState.clock = Clock.new()


func _advance(seconds: int) -> void:
	clock.advance(seconds)
	GameState.tick()
	main.panel._on_second()


func _panel() -> BuildingPanel:
	return main.panel


func _confirm() -> SpeedupConfirm:
	return main.speedup_confirm


func _shells() -> int:
	return GameState.wallet.balance(&"shells")


## Séjour de Camille et Noé (2 nuits, commission 120) qui commence, panneau ouvert.
func _start_stay(free_offer := true) -> Lodging:
	if not free_offer:
		GameState.free_speedups = 0
	GameState.accept_offer(GameState.bookings.offers[0].id)
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	_advance(GameState.timings.cleaning_seconds)
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	main.select_building(main.map.buildings[&"hibiscus_1"])
	return GameState.get_lodging(&"hibiscus_1")


func _button(tier: T) -> Button:
	return _panel().speedup_box.get_node("Speedup_" + T.keys()[tier]) as Button


## Appui sur un bouton du panneau (action différée après le toucher).
func _press(button: Button) -> void:
	button.pressed.emit()
	await get_tree().process_frame


## Empreinte de tout ce qu'une annulation ne doit pas toucher.
func _snapshot() -> String:
	return JSON.stringify(GameState.to_save_dict())


func test_section_appears_only_during_a_stay() -> void:
	main.select_building(main.map.buildings[&"hibiscus_1"])
	assert_false(_panel().speedup_box.visible, "logement libre")
	GameState.accept_offer(GameState.bookings.offers[0].id)
	assert_false(_panel().speedup_box.visible, "réservé")
	GameState.add_items({&"welcome_basket": 1})
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.PREPARE)
	assert_false(_panel().speedup_box.visible, "ménage (renfort : lot 3)")
	_advance(GameState.timings.cleaning_seconds)
	assert_false(_panel().speedup_box.visible, "prêt")
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.WELCOME_GUESTS)
	assert_true(_panel().speedup_box.visible, "séjour en cours")
	assert_eq(_panel().speedup_buttons().size(), 2)
	_advance(600)
	assert_false(_panel().speedup_box.visible, "séjour terminé")


func test_buttons_are_discreet_comfortable_and_show_their_price() -> void:
	_start_stay()
	for button in _panel().speedup_buttons():
		assert_eq(button.theme_type_variation, &"SecondaryButton", "style secondaire, discret")
		assert_gte(button.custom_minimum_size.y, 96.0, "zone tactile confortable")
		assert_false(button.disabled)
	assert_eq(_button(T.ONE_NIGHT).text, "Passer une nuit · 9 coquillages")
	assert_eq(_button(T.FINISH).text, "Terminer le séjour · offert (offre unique)")
	var texts := _panel().speedup_box.get_children().filter(func(n): return n is Label).map(func(l): return l.text)
	assert_has(texts, "Facultatif : le séjour se termine aussi tout seul.")


func test_short_balance_disables_buttons_with_the_missing_amount() -> void:
	_start_stay(false)
	GameState.spend({&"shells": 45})
	assert_true(_button(T.FINISH).disabled)
	assert_eq(_button(T.FINISH).text, "Terminer le séjour · il manque 13 coquillages")
	GameState.earn(&"shells", 100, &"test")
	assert_false(_button(T.FINISH).disabled, "réactivé dès que le solde suffit")


func test_confirmation_shows_gain_price_and_balance_before_any_effect() -> void:
	_start_stay()
	var before := _snapshot()
	await _press(_button(T.ONE_NIGHT))
	var c := _confirm()
	assert_true(c.visible)
	assert_eq(c.title.text, "Passer une nuit ?")
	assert_eq(c.gain_value.text, "5 min")
	assert_eq(c.price_value.text, "9 coquillages")
	assert_eq(c.balance_value.text, "41 coquillages")
	assert_false(c.offer_note.visible)
	assert_eq(c.confirm_button.text, "Confirmer")
	assert_false(c.confirm_button.disabled)
	assert_gte(c.confirm_button.custom_minimum_size.y, 96.0)
	assert_gte(c.cancel_button.custom_minimum_size.y, 96.0)
	assert_eq(_snapshot(), before, "rien n'est payé avant « Confirmer »")


func test_offer_is_labelled_as_unique_and_needs_explicit_confirmation() -> void:
	_start_stay()
	await _press(_button(T.FINISH))
	var c := _confirm()
	assert_eq(c.price_value.text, "Offert")
	assert_true(c.offer_note.visible)
	assert_string_contains(c.offer_note.text, "Offre unique")
	assert_string_contains(c.offer_note.text, "une seule fois par partie")
	assert_eq(c.confirm_button.text, "Utiliser l'offre")
	assert_eq(GameState.free_speedups, 1, "pas consommée à l'ouverture")
	c.confirm_button.pressed.emit()
	await get_tree().process_frame
	assert_false(c.visible)
	assert_eq(GameState.free_speedups, 0, "consommée à la confirmation")
	assert_eq(_shells(), 50)
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.STAY_COMPLETE)


func test_offer_is_consumed_only_once() -> void:
	_start_stay()
	await _press(_button(T.FINISH))
	_confirm().confirm()
	GameState.perform_lodging_action(&"hibiscus_1", Lodging.Action.COLLECT_COMMISSION)
	_advance(60)
	_start_stay()  # séjour suivant : Léa, 1 nuit, commission 50
	var quote: Dictionary = GameState.quote_stay_speedup(&"hibiscus_1", T.FINISH).value
	assert_false(quote.free, "plus d'offre")
	assert_eq(quote.cost, 8, "15 % de 50, arrondi")
	assert_eq(_button(T.FINISH).text, "Terminer le séjour · 8 coquillages")
	await _press(_button(T.FINISH))
	assert_eq(_confirm().price_value.text, "8 coquillages")
	assert_false(_confirm().offer_note.visible)


func test_cancel_tap_outside_or_escape_have_no_effect() -> void:
	_start_stay()
	var before := _snapshot()
	var history := GameState.wallet.history.size()
	# Annuler
	await _press(_button(T.FINISH))
	_confirm().cancel_button.pressed.emit()
	assert_false(_confirm().visible)
	# Toucher le fond
	await _press(_button(T.ONE_NIGHT))
	var release := InputEventScreenTouch.new()
	release.pressed = false
	_confirm()._on_backdrop_input(release)
	assert_false(_confirm().visible)
	# Échap / retour
	await _press(_button(T.ONE_NIGHT))
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	_confirm()._unhandled_input(escape)
	assert_false(_confirm().visible)
	assert_eq(_snapshot(), before, "aucun effet")
	assert_eq(GameState.wallet.history.size(), history)
	assert_eq(GameState.free_speedups, 1, "offre intacte")


func test_confirming_applies_once_and_progress_never_goes_back() -> void:
	var lodging := _start_stay(false)
	await _press(_button(T.ONE_NIGHT))
	_confirm().confirm_button.pressed.emit()
	await get_tree().process_frame
	assert_false(_confirm().visible)
	assert_eq(_shells(), 41)
	assert_eq(lodging.removed_seconds(), 300)
	assert_almost_eq(_panel().progress.value, 50.0, 0.01, "la barre avance, elle ne repart pas de zéro")
	assert_string_starts_with(_panel().progress_label.text, "Nuit 2/2", "une nuit est passée")
	assert_true(main.toasts.messages()[-1].begins_with("Le temps file à Mahana"), "retour discret")


func test_double_tap_on_confirm_is_paid_once() -> void:
	_start_stay(false)
	await _press(_button(T.ONE_NIGHT))
	_confirm().confirm_button.pressed.emit()
	_confirm().confirm_button.pressed.emit()
	await get_tree().process_frame
	assert_eq(_shells(), 41, "un seul paiement")
	assert_eq(GameState.get_lodging(&"hibiscus_1").removed_seconds(), 300)


func test_double_tap_on_the_panel_button_opens_a_single_confirmation() -> void:
	_start_stay(false)
	_button(T.ONE_NIGHT).pressed.emit()
	_button(T.ONE_NIGHT).pressed.emit()
	await get_tree().process_frame
	assert_true(_confirm().visible)
	assert_eq(main.hud.get_children().filter(func(n): return n is SpeedupConfirm).size(), 1)
	assert_eq(_shells(), 50, "ouvrir n'est pas payer")


## Exigence 5 : séjour terminé entre l'ouverture et la validation.
func test_stay_ending_naturally_while_open_is_refused_without_debit() -> void:
	_start_stay(false)
	await _press(_button(T.ONE_NIGHT))
	var history := GameState.wallet.history.size()
	# Le temps passe sans que l'écran soit rafraîchi : seule la validation compte.
	clock.advance(700)
	_confirm().confirm()
	assert_eq(_shells(), 50, "aucun débit")
	assert_true(_confirm().visible, "la confirmation explique le refus")
	assert_true(_confirm().confirm_button.disabled)
	assert_eq(_confirm().status.text, "Le séjour est terminé : rien à accélérer.")
	GameState.tick()
	assert_eq(GameState.get_lodging(&"hibiscus_1").state, Lodging.State.STAY_COMPLETE)
	assert_eq(GameState.wallet.history.size(), history, "aucun mouvement d'argent")
	assert_eq(GameState.get_lodging(&"hibiscus_1").speedups.size(), 0, "aucune accélération enregistrée")


## Exigence 6 : solde modifié pendant que la confirmation est ouverte.
func test_balance_change_while_open_is_rechecked() -> void:
	_start_stay(false)
	await _press(_button(T.ONE_NIGHT))
	var c := _confirm()
	GameState.spend({&"shells": 45})
	assert_true(c.confirm_button.disabled, "revérifié aussitôt")
	assert_eq(c.status.text, "Il manque 4 coquillages.")
	c.confirm()
	assert_eq(_shells(), 5, "validation forcée : refus sans débit")
	GameState.earn(&"shells", 100, &"test")
	assert_false(c.confirm_button.disabled)
	assert_eq(c.balance_value.text, "96 coquillages", "solde après recalculé")
	c.confirm()
	assert_eq(_shells(), 96)


## Prix affiché « Offert », mais l'offre a été utilisée entre-temps.
func test_price_rising_after_display_is_refused_without_debit() -> void:
	_start_stay()
	await _press(_button(T.FINISH))
	var c := _confirm()
	assert_eq(c.price_value.text, "Offert")
	GameState.free_speedups = 0  # utilisée ailleurs, sans rafraîchissement
	c.confirm()
	assert_eq(_shells(), 50, "aucun débit")
	assert_true(c.visible)
	assert_eq(c.status.text, "Le prix a changé : vérifiez avant de confirmer.")
	assert_eq(c.price_value.text, "18 coquillages", "nouveau prix affiché")


func test_a_starting_dialogue_or_closing_the_panel_cancels_the_confirmation() -> void:
	_start_stay()
	var before := _snapshot()
	await _press(_button(T.FINISH))
	main.dialogue_box.play(load("res://data/dialogues/dlg_tutorial_09.tres"))
	assert_false(_confirm().visible, "un dialogue ferme la confirmation")
	main.dialogue_box.skip()
	main.select_building(main.map.buildings[&"hibiscus_1"])
	await _press(_button(T.FINISH))
	_panel().close_panel()
	assert_false(_confirm().visible, "fermer le panneau ferme la confirmation")
	assert_eq(_snapshot(), before)


func test_confirmation_blocks_the_map_behind_it() -> void:
	_start_stay()
	var center := Vector2(400, 900)
	assert_false(main.hud.is_point_over_ui(center))
	await _press(_button(T.ONE_NIGHT))
	assert_true(main.hud.is_point_over_ui(center), "aucun geste ne traverse la confirmation")


func test_hina_mentions_the_offer_without_pushing_to_spend() -> void:
	var dialogue: DialogueDef = load("res://data/dialogues/dlg_tutorial_09.tres")
	assert_eq(dialogue.lines.size(), 3)
	var text := tr(dialogue.lines[2].text_key)
	assert_eq(dialogue.lines[2].speaker.id, &"npc_hina")
	assert_string_contains(text, "avancer le temps")
	assert_string_contains(text, "La première fois, c'est moi qui offre")
	assert_string_contains(text, "rien ne presse")


func test_secondary_button_text_is_readable() -> void:
	var theme: Theme = load("res://scenes/ui/theme.tres")
	var text := theme.get_color(&"font_color", &"SecondaryButton")
	var bg := (theme.get_stylebox(&"normal", &"SecondaryButton") as StyleBoxFlat).bg_color
	var panel_bg := (theme.get_stylebox(&"panel", &"PanelContainer") as StyleBoxFlat).bg_color
	var shown := panel_bg.lerp(Color(bg.r, bg.g, bg.b), bg.a)  # fond légèrement transparent sur le panneau
	var lum := func(c: Color) -> float:
		var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
		return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)
	var a: float = lum.call(text)
	var b: float = lum.call(shown)
	assert_gte((maxf(a, b) + 0.05) / (minf(a, b) + 0.05), 4.5, "contraste WCAG du texte")
