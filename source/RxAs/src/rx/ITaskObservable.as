package rx
{
	import rx.subjects.IConnectableObservable;
	
	public interface ITaskObservable extends IConnectableObservable
	{
		function get whenProgressChanged() : IObservable;
	}
}