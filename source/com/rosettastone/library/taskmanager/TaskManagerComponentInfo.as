package com.rosettastone.library.taskmanager {
	
	/**
	 * Used for retrieving information about the TaskManager component.
	 */
	public class TaskManagerComponentInfo {
		
		private static const majorVersion:int = 0;
		private static const minorVersion:int = 0;
		private static const buildVersion:int = 0;
		
		/**
		 * Returns a string with the three version numbers, seperated by
		 * '.' - e.g. 3.1.2 or 0.1.23
		 */
		public static function getVersionString():String {
			return getMajorVersion() + "." + getMinorVersion() + "." + getBuildVersion();
		}
		
		/**
		 * Returns the major version number of this component.
		 */
		public static function getMajorVersion():int {
			return majorVersion;
		}
		
		/**
		 * Returns the minor version number of this component.
		 */
		public static function getMinorVersion():int {
			return minorVersion;
		}
		
		/**
		 * Returns the build version number of this component.
		 */
		public static function getBuildVersion():int {
			return buildVersion;
		}
	}
}
