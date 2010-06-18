package rx
{
	import rx.subjects.ConnectableObservable;

	public class TaskObservable extends ConnectableObservable implements ITaskObservable
	{
		private var _progressObservable : IObservable;
		
		public function TaskObservable(source:IObservable, progressObservable : IObservable, connectionSubject:ISubject=null)
		{
			super(source, connectionSubject);
			
			_progressObservable = progressObservable;
		}
		
		public function get whenProgressChanged():IObservable
		{
			return _progressObservable;
		}
	}
}