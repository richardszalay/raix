package raix.reactive.flex
{
	import flash.errors.IllegalOperationError;
	
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.rpc.AsyncToken;
	
	import raix.reactive.*;
	import raix.reactive.scheduling.*;
	
	public class FlexObservable
	{
		public function FlexObservable()
		{
			throw new IllegalOperationError("This class is static and cannot be instantiated. Create an IObservable by using one of FlexObservable's static methods");
		}
		
		/**
		 * Creates a sequence consisting of the values in a list 
		 * @param elementClass The class common to all values in values
		 * @param values The list of values to iterate through
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of elementType
		 */
		public static function fromList(elementClass : Class, list : IList, scheduler : IScheduler	= null) : IObservable
		{
			return Observable.generate(
				0,
				function(i : int):Boolean { return i < list.length; },
				function(i : int):int { return i+1; },
				function(i : int):Object { return list.getItemAt(i); },
				scheduler);
		}

		/**
		 * Creates a sequence consisting of the values in a collection 
		 * @param elementClass The class common to all values in values
		 * @param values The collection of values to iterate through
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of elementType
		 */
		public static function fromCollection(elementClass : Class, collection : ICollectionView, scheduler : IScheduler	= null) : IObservable
		{
			return Observable.defer(function():IObservable
			{
				return fromViewCursor(collection.createCursor());
			});
		}
		
		/**
		 * Creates a sequence consisting of the values in a view cursor 
		 * @param elementClass The class common to all values in values
		 * @param values The view cursor of values to iterate through
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of elementClass
		 */
		public static function fromViewCursor(cursor : IViewCursor, scheduler : IScheduler	= null) : IObservable
		{
			return Observable.generate(
				true,
				function(state : Boolean):Boolean { return state; },
				function(state : Boolean):Boolean { return cursor.moveNext(); },
				function(state : Boolean):Object { return cursor.current; },
				scheduler);
		}
		
		/**
		 * Creates an observable sequence from a function that returns an AsyncToken 
		 * @param valueClass The class of the value returned by the AsyncToken
		 * @param asyncMethod The method to execute when a new subscription occurs. This method must return AsyncToken
		 * @param args The arguments to supply to asyncMethod
		 * @return An observable sequence of valueClass
		 */			
		public static function fromAsyncPattern(valueClass : Class, asyncMethod : Function, 
			args : Array) : IObservable 
		{
			return Observable.defer(function():IObservable
			{
				// TODO: Catch/rethrow valueClass coercion error here?
				var token : AsyncToken = asyncMethod.apply(NaN, args);
				
				var responder : IObservableResponder = responder(valueClass);
				token.addResponder(responder);
				
				return responder;
			});
		}
		
		/**
		 * Creates an observable sequence that is also an IResponder 
		 * @param valueClass The valueClass of the returned sequence
		 * @return An observable sequence of valueClass
		 */			
		public static function responder(valueClass : Class) : IObservableResponder
		{
			return new ObservableResponder(valueClass);
		}
	}
}