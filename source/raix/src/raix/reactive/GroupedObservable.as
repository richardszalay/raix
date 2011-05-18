package raix.reactive
{
	internal class GroupedObservable extends AbsObservable implements IGroupedObservable
	{
		private var _underlyingObservable : IObservable;
		private var _key : Object;
		
		public function GroupedObservable(key : Object, underlyingObservable : IObservable)
		{
			_underlyingObservable = underlyingObservable;
			_key = key;			
		}
		
		public function get key() : Object
		{
			return _key;
		}
		
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			return _underlyingObservable.subscribeWith(observer);
		}
	}
}