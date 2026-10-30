## Bus de signaux global (autoload `EventBus`).
##
## Les règles métier et la présentation ne se connaissent pas directement :
## elles communiquent par ces signaux. Chaque étape du plan ajoute ici les
## signaux dont elle a besoin (voir docs/ARCHITECTURE.md §5).
extends Node
@warning_ignore_start("unused_signal")

## Un logement a changé d'état (Lodging.State).
signal lodging_state_changed(lodging_uid: StringName, state: int)
## Une commande a été refusée ; `error_code` → clé i18n "ERR_<CODE>".
signal action_failed(error_code: StringName, params: Dictionary)
## Le solde d'une monnaie a changé.
signal currency_changed(currency_id: StringName, balance: int)
## La quantité d'un objet a changé.
signal inventory_changed(item_id: StringName, count: int)
## La liste des offres de réservation du bureau a changé.
signal offers_changed
## Une offre a été acceptée pour un logement.
signal booking_accepted(booking_id: StringName, lodging_uid: StringName)
## Un séjour vient de se terminer (automatiquement) ; commission à encaisser.
signal stay_completed(lodging_uid: StringName, booking_id: StringName, commission: int)
## Une commission a été versée à la conciergerie.
signal commission_collected(lodging_uid: StringName, booking_id: StringName, amount: int)
## Une production a été lancée.
signal production_started(building_uid: StringName, recipe_id: StringName)
## Une production terminée a été livrée à l'inventaire.
signal production_completed(building_uid: StringName, recipe_id: StringName)
## Des objets ont été récoltés ou fabriqués (objectifs de quête « item_collected »).
signal item_collected(item_id: StringName, amount: int)
## Une production terminée attend de la place dans l'inventaire (ou n'attend plus).
signal production_blocked_changed(building_uid: StringName, blocked: bool)
## Expérience totale et niveau après un gain.
signal xp_changed(xp: int, level: int)
## Un gain d'expérience (pour les retours visuels).
signal xp_gained(amount: int, reason: StringName)
## Le joueur passe au niveau `level`.
signal level_up(level: int)
## Événement de jeu pouvant faire avancer une quête (voir GameEvents).
signal game_event(event: StringName, target: StringName, amount: int)
## Une quête devient disponible (son dialogue d'introduction peut être joué).
signal quest_available(quest_id: StringName)
## Une quête démarre / progresse / se termine.
signal quest_started(quest_id: StringName)
signal quest_progressed(quest_id: StringName)
signal quest_completed(quest_id: StringName)
## Fin d'une mise à jour du temps (chaque seconde) : rafraîchir les animations.
signal ticked
