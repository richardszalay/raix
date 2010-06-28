
		import rx.ICancelable;
		
		public function where(predicate:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
			{
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						var result : Boolean = false;
						
						try
						{
							result = predicate(value);
						}
						catch(err : Error)
						{
							observer.onError(err);
						}
							
						if (result)
						{
							observer.onNext(value);
						}
					},
					observer.onCompleted,
					observer.onError
					);
				
				return source.subscribeWith(decoratorObserver);
			});
		}