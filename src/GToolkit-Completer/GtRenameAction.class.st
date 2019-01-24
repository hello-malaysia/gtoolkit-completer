Class {
	#name : #GtRenameAction,
	#superclass : #Object,
	#instVars : [
		'textElement',
		'editorHandlers',
		'elementFilters',
		'originalLocations',
		'originalText',
		'originalCursorPosition',
		'originalIndex',
		'shouldSelectNames',
		'isInstalled',
		'escapeCancels'
	],
	#category : #'GToolkit-Completer-Actions'
}

{ #category : #pharo }
GtRenameAction class >> findVariableNodeIn: astNode at: anInteger [
	astNode
		withAllNodesDo: [ :node | 
			((node isKindOf: GtPharoVariableNode) and: [ anInteger between: node startPosition and: node stopPosition ])
				ifTrue: [ ^ node ] ]
		andTokensDo: [ :each |  ]
		includesErrors: true.
	^ nil
]

{ #category : #'instance creation' }
GtRenameAction class >> locations: aCollectionOfIntervals element: aTextEditorElement [
	^ self new
		textElement: aTextEditorElement;
		locations: aCollectionOfIntervals;
		yourself
]

{ #category : #pharo }
GtRenameAction class >> pharoRenameLocalsOn: aTextEditorElement [
	^ [ | editor text ast items action |
	editor := aTextEditorElement editor.
	editor cursor cursorsCount = 1
		ifFalse: [ ^ nil ].
	text := editor text.
	ast := GtPharoParser parseWithErrors: text asString.
	items := OrderedCollection new.
	(self findVariableNodeIn: ast at: editor cursor first position)
		ifNotNil: [ :node | 
			node whoDefines
				ifNotNil: [ :definer | 
					definer
						withAllNodesDo: [ :each | 
							each = node
								ifTrue: [ items add: (each startPosition to: each stopPosition) ] ]
						andTokensDo: nil
						includesErrors: true ] ].
	action := self locations: items element: aTextEditorElement.
	action install ]
		on: Error
		do: [ :ex | ex return: nil ]
]

{ #category : #pharo }
GtRenameAction class >> pharoRenameSnippetLocalsOn: aTextEditorElement [
	^ [ | editor text ast items action |
	editor := aTextEditorElement editor.
	editor cursor cursorsCount = 1
		ifFalse: [ ^ nil ].
	text := editor text.
	ast := GtPharoParser parseWithErrors: text asString startingAt: GtPharoParser startingStateForMethodSequence.
	items := OrderedCollection new.
	(self findVariableNodeIn: ast at: editor cursor first position)
		ifNotNil: [ :node | 
			| definer |
			definer := node whoDefines ifNil: [ ast ].
			definer
				withAllNodesDo: [ :each | 
					each = node
						ifTrue: [ items add: (each startPosition to: each stopPosition) ] ]
				andTokensDo: nil
				includesErrors: true ].
	action := self locations: items element: aTextEditorElement.
	action install ]
		on: Error
		do: [ :ex | ex return: nil ]
]

{ #category : #actions }
GtRenameAction >> accept [
	self uninstall.
	self removeExtraCursors
]

{ #category : #private }
GtRenameAction >> addCursors [
	| offset navigator |
	originalIndex := self intervalForPosition: originalCursorPosition.
	offset := originalCursorPosition - (originalLocations at: originalIndex) first.
	navigator := self textEditor navigator.
	navigator removeAll.
	originalLocations do: [ :each | navigator addAt: each first + offset ].
	navigator apply
]

{ #category : #private }
GtRenameAction >> addRenameAttributes [
	| text |
	text := self text.
	originalLocations
		do: [ :each | 
			(text from: each first to: each last) attributes: {GtRenameAttribute new}.
			self textEditor invalidate: each first to: each last.
			self textEditor update: each first to: each last ]
]

{ #category : #actions }
GtRenameAction >> cancel [
	self uninstall.
	self undoChanges
]

{ #category : #'event handling' }
GtRenameAction >> cursorEvent: anEvent [
	self uninstall
]

{ #category : #installation }
GtRenameAction >> editorEventHandlers [
	^ {(BlEventHandler
		on: BrTextEditorCursorAddedEvent
		do: [ :event | self cursorEvent: event ]).
	(BlEventHandler
		on: BrTextEditorCursorRemovedEvent
		do: [ :event | self cursorEvent: event ]).
	(BlEventHandler
		on: BrTextEditorInsertedEvent
		do: [ :event | self textInserted: event ])}
]

{ #category : #installation }
GtRenameAction >> elementEventHandlers [
	^ {(BlEventHandler
		on: BlKeystrokeEvent
		do: [ :event | self processKeystroke: event ]).
	(BlEventHandler
		on: BlKeyDownEvent
		do: [ :event | self processKeyDown: event ])}
]

{ #category : #accessing }
GtRenameAction >> escapeCancels [
	^ escapeCancels
]

{ #category : #accessing }
GtRenameAction >> escapeCancels: aBoolean [
	escapeCancels := aBoolean
]

{ #category : #'initialize-release' }
GtRenameAction >> initialize [
	super initialize.
	originalLocations := #().
	editorHandlers := #().
	elementFilters := #().
	shouldSelectNames := false.
	isInstalled := false.
	escapeCancels := true
]

{ #category : #installation }
GtRenameAction >> install [
	originalLocations isEmpty
		ifTrue: [ ^ self ].
	self saveOriginalState.
	self addRenameAttributes.
	self addCursors.
	self installEventHandlers.
	self selectNames.
	isInstalled := true
]

{ #category : #installation }
GtRenameAction >> installEventHandlers [
	editorHandlers := self editorEventHandlers.
	editorHandlers do: [ :each | self textEditor addEventHandler: each ].
	elementFilters := self elementEventHandlers.
	elementFilters do: [ :each | self textElement addEventFilter: each ]
]

{ #category : #private }
GtRenameAction >> intervalForPosition: aPosition [
	originalLocations
		keysAndValuesDo: [ :i :each | 
			(aPosition between: each first - 1 and: each last)
				ifTrue: [ ^ i ] ].
	^ 0
]

{ #category : #testing }
GtRenameAction >> isInstalled [
	^ isInstalled
]

{ #category : #testing }
GtRenameAction >> isRenameAttribute: anAttribute [
	^ anAttribute isKindOf: GtRenameAttribute
]

{ #category : #accessing }
GtRenameAction >> locations: aCollectionOfIntervals [
	originalLocations := aCollectionOfIntervals asSortedCollection: [ :a :b | a first < b first ].
	self validateLocations
]

{ #category : #'event handling' }
GtRenameAction >> processKeyDown: anEvent [
	(escapeCancels and: [ anEvent key = Key escape ])
		ifTrue: [ self cancel.
			anEvent consumed: true ]
]

{ #category : #'event handling' }
GtRenameAction >> processKeystroke: anEvent [
	(anEvent char = Character tab or: [ anEvent char = Character cr ])
		ifTrue: [ self accept.
			anEvent consumed: true ]
]

{ #category : #private }
GtRenameAction >> removeAttributes [
	self text clearAttributes: [ :each | self isRenameAttribute: each ].
	self textEditor invalidate: 1 to: self text size.
	self textEditor update: 1 to: self text size
]

{ #category : #private }
GtRenameAction >> removeExtraCursors [
	| count |
	self textEditor cursor cursorsCount = originalLocations size
		ifFalse: [ ^ self ].
	count := 1.
	(self textEditor cursor allCursors asSortedCollection: [ :a :b | a position < b position ])
		do: [ :each | 
			count = originalIndex
				ifTrue: [ ^ self textEditor navigator
						removeAll;
						addAt: each position;
						apply ].
			count := count + 1 ]
]

{ #category : #private }
GtRenameAction >> saveOriginalState [
	| text |
	text := self text.
	originalText := text copy.
	originalCursorPosition := self textEditor cursor first position
]

{ #category : #private }
GtRenameAction >> selectNames [
	| selecter |
	shouldSelectNames
		ifFalse: [ ^ self ].
	selecter := self textEditor selecter.
	originalLocations do: [ :each | selecter from: each first - 1 to: each last ].
	selecter select
]

{ #category : #accessing }
GtRenameAction >> shouldSelectNames [
	^ shouldSelectNames
]

{ #category : #accessing }
GtRenameAction >> shouldSelectNames: aBoolean [
	shouldSelectNames := aBoolean
]

{ #category : #accessing }
GtRenameAction >> text [
	^ self textEditor text
]

{ #category : #accessing }
GtRenameAction >> textEditor [
	^ self textElement editor
]

{ #category : #accessing }
GtRenameAction >> textElement [
	^ textElement
]

{ #category : #accessing }
GtRenameAction >> textElement: aTextEditorElement [
	textElement := aTextEditorElement
]

{ #category : #'event handling' }
GtRenameAction >> textInserted: anEvent [
	| from to |
	from := anEvent index + 1.
	to := anEvent index + anEvent text size.
	((self textEditor text attributesAt: from) anySatisfy: [ :each | each isKindOf: GtRenameAttribute ])
		ifTrue: [ ^ self ].
	(self textEditor text from: from to: to) attributes: {GtRenameAttribute new}.
	self textEditor invalidate: from to: to.
	self textEditor update: from to: to
]

{ #category : #private }
GtRenameAction >> undoChanges [
	self textEditor text: originalText.
	self textEditor moveCursorTo: originalCursorPosition
]

{ #category : #installation }
GtRenameAction >> uninstall [
	self uninstallEventHandlers.
	self removeAttributes.
	isInstalled := false
]

{ #category : #installation }
GtRenameAction >> uninstallEventHandlers [
	elementFilters do: [ :each | self textElement removeEventFilter: each ].
	editorHandlers do: [ :each | self textEditor removeEventHandler: each ]
]

{ #category : #private }
GtRenameAction >> validateLocations [
	| lastLocation size |
	originalLocations isEmpty
		ifTrue: [ ^ self ].
	lastLocation := 0.
	size := originalLocations first size.
	originalLocations
		do: [ :each | 
			each first <= lastLocation
				ifTrue: [ self error: 'Cannot rename overlapping locations' ].
			lastLocation := each last.
			each size ~= size
				ifTrue: [ self error: 'Cannot rename items of different sizes' ] ]
]