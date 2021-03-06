"
I am a custom shortcut handler to be used by completion controller.

I only process shortcuts if a completion popup is opened, otherwise I ignore them
"
Class {
	#name : #GtCompletionShortcutHander,
	#superclass : #BlShortcutHandlerWithShortcuts,
	#instVars : [
		'completionController',
		'consumeEvent',
		'whenActive'
	],
	#category : #'GToolkit-Completer-UI'
}

{ #category : #accessing }
GtCompletionShortcutHander >> completionController [
	<return: #GtCompletionController>

	^ completionController
]

{ #category : #accessing }
GtCompletionShortcutHander >> completionController: aCompletionController [
	completionController := aCompletionController
]

{ #category : #accessing }
GtCompletionShortcutHander >> consumeEvent [
	^ consumeEvent
]

{ #category : #accessing }
GtCompletionShortcutHander >> consumeEvent: aBoolean [
	consumeEvent := aBoolean
]

{ #category : #'api - event managing' }
GtCompletionShortcutHander >> handleEvent: anEvent [
	consumeEvent := true.
	super handleEvent: anEvent.
	consumeEvent
		ifFalse: [ anEvent consumed: false ]
]

{ #category : #'initialize-release' }
GtCompletionShortcutHander >> initialize [
	super initialize.
	whenActive := true
]

{ #category : #'api - event managing' }
GtCompletionShortcutHander >> wantsEvent: anEvent [
	^ self completionController isActive = whenActive
		and: [ super wantsEvent: anEvent ]
]

{ #category : #'initialize-release' }
GtCompletionShortcutHander >> whenActive [
	whenActive := true
]

{ #category : #'initialize-release' }
GtCompletionShortcutHander >> whenInactive [
	whenActive := false
]
