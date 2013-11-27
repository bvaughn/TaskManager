package com.rosettastone.library.taskmanager {
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	
	/**
	 * Task that plays a Sound and completes when the sound has finished playing.
	 * This Task expects that the Sound object provided has already been loaded.
	 * 
	 * This task supports interruption as well as resume.
	 * Upon resuming an interrupted Sound this Task can either re-start playback at the beginning or resume from the interrupted point.
	 * This behavior can be controlled via the constructor parameter "restartSoundAfterInterruption".
	 */
	public class PlaySoundTask extends InterruptibleTask {
		
		protected var _interruptedPosition:int;
		protected var _restartSoundAfterInterruption:Boolean;
		protected var _sound:Sound;
		protected var _soundChannel:SoundChannel;
		
		/**
		 * Constructor.
		 * 
		 * @param sound Loaded Sound object to be played
		 * @param restartSoundAfterInterruption Specifies the resume-after-interruption behavior
		 */
		public function PlaySoundTask( sound:Sound,
		                               restartSoundAfterInterruption:Boolean = true,
		                               taskIdentifier:String = null ) {
			
			super( taskIdentifier );
			
			_restartSoundAfterInterruption = restartSoundAfterInterruption;
			_sound = sound;
			
			_interruptedPosition = 0;
		}
		
		public function get sound():Sound {
			return _sound;
		}
		
		public function get soundChannel():SoundChannel {
			return _soundChannel;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			if ( _soundChannel ) {
				_interruptedPosition = _soundChannel.position;
				
				_soundChannel.removeEventListener( Event.SOUND_COMPLETE, onSoundComplete );
				_soundChannel.stop();
				_soundChannel = null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			try {
				_soundChannel = _sound.play( _restartSoundAfterInterruption ? 0 : _interruptedPosition );
				_soundChannel.addEventListener( Event.SOUND_COMPLETE, onSoundComplete );
				
				_interruptedPosition = 0;
				
			} catch ( error:Error ) {
				taskError( error.message );
			}
		}
		
		/*
		 * Event handlers
		 */
		
		private function onSoundComplete( event:Event ):void {
			event.currentTarget.removeEventListener( Event.COMPLETE, onSoundComplete );
			
			taskComplete();
		}
	}
}