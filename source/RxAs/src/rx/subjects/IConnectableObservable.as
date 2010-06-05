package rx.subjects
{
	import rx.ICancelable;
	import rx.IObservable;
	
	public interface IConnectableObservable extends IObservable
	{
		function connect() : ICancelable;
	}
}