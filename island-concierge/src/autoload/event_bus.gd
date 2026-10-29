## Bus de signaux global (autoload `EventBus`).
##
## Les règles métier et la présentation ne se connaissent pas directement :
## elles communiquent par ces signaux. Chaque étape du plan ajoute ici les
## signaux dont elle a besoin (voir docs/ARCHITECTURE.md §5).
extends Node
