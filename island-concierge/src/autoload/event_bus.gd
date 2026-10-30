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
