package rx
{
	/**
	 * Enumeration for the different types of Notification
	 */
	public class NotificationKind
	{
		/**
		 * An onNext (value) message
		 * 
		 * @see rx.OnNext
		 */
		public static const ON_NEXT : int = 0;
		
		/**
		 * An onError message
		 * 
		 * @see rx.OnError
		 */
		public static const ON_ERROR : int = 1;
		
		/**
		 * An onCompleted message
		 * 
		 * @see rx.OnCompleted
		 */
		public static const ON_COMPLETED : int = 2;
	}
}