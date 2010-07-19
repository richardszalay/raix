package rx.flex
{
	import mx.rpc.IResponder;
	
	import rx.IObservable;
	
	/**
	 * An observable sequence that is also an mx.rpc.IResponse
	 */	
	public interface IObservableResponder extends IResponder, IObservable
	{
	}
}