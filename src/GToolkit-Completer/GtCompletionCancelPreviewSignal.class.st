Class {
	#name : #GtCompletionCancelPreviewSignal,
	#superclass : #ContextStackSignal,
	#instVars : [
		'action'
	],
	#category : 'GToolkit-Completer-Signals'
}

{ #category : #accessing }
GtCompletionCancelPreviewSignal >> action [
	^ action
]

{ #category : #accessing }
GtCompletionCancelPreviewSignal >> action: anObject [
	action := anObject
]

{ #category : #printing }
GtCompletionCancelPreviewSignal >> printOneLineContentsOn: aStream [

	self action ifNil: [ 
		aStream
			<< 'a ';
			print: self class name;
			<< ' without an action'.
		^self ].
	self action label printOn: aStream
]
