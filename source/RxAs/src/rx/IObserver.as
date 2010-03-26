package rx
{
	public interface IObserver
	{
		function onCompleted() : void;
    	function onError(error : Error) : void;
    	function onNext(value : Object) : void;
	}
}