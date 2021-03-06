Extension { #name : #GtPharoVariableNode }

{ #category : #'*GToolkit-Completer' }
GtPharoVariableNode >> completionActionsFor: aStrategy [
	| prefix variables allLocalVariables |
	self name stopPosition = aStrategy index
		ifFalse: [ ^ #() ].
	prefix := name source.
	allLocalVariables := aStrategy localVariablesFor: self.
	variables := allLocalVariables
		first: aStrategy maxItems
		startingWith: prefix.
	variables
		addAll:
			(aStrategy variables
				first: aStrategy maxItems - variables size
				startingWith: prefix).
	^ variables
		collect: [ :each | 
			GtInsertTextCompletionAction
				labeled: each
				completion: (each allButFirst: prefix size)
				position: aStrategy index ]
]

{ #category : #'*GToolkit-Completer' }
GtPharoVariableNode >> guessType: completionStrategy [
	^ (completionStrategy typeOfVariable: name value) ifNil: [ super guessType: completionStrategy ]
]

{ #category : #'*GToolkit-Completer' }
GtPharoVariableNode >> isLocallyDefined [
	^ self allParents anySatisfy: [ :each | each defines: name value ]
]

{ #category : #'*GToolkit-Completer' }
GtPharoVariableNode >> whoDefines [
	^ self allParents detect: [ :each | each defines: name value ] ifNone: [  ]
]
