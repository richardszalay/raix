package rx
{
	import flash.errors.IllegalOperationError;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import rx.impl.*;
	import rx.scheduling.*;
	import rx.subjects.AsyncSubject;
	import rx.subjects.ConnectableObservable;
	import rx.subjects.IConnectableObservable;
	import rx.subjects.ReplaySubject;
	
	/**
	 * Subclass this class only if you want to implement a completely custom IObservable.
	 * 
	 * <p>If you can avoid it, however, try to stick to subclassing Subject or using 
	 * one of the creation methods.</p>
	 * 
	 * <p>This class may be made inaccessible in future revisions</p>
	 */
	public class AbsObservable implements IObservable
	{
		public function AbsObservable()
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function get valueClass() : Class
		{
			return Object;
		}
		
		/**
		 * @inheritDoc
		 */
		public function subscribeWith(observer : IObserver) : ICancelable
		{
			// Abstract methods not supported by AS3
			throw new IllegalOperationError("subscribe() must be overriden");
		}
		
		/**
		 * @inheritDoc
		 */
		public function subscribe(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : ICancelable
		{
			var observer : IObserver = new ClosureObserver(onNext, onComplete, onError);
			
			return subscribeWith(observer);
		}
		
		/**
		 * @inheritDoc
		 */
		public function and(right : IObservable) : Pattern
		{
			return new Pattern([this, right]);
		}

		/**
		 * @inheritDoc
		 */
		public function aggregate(accumulator : Function, valueClass : Class = null, initialValue : Object = null) : IObservable
		{
			return scan(accumulator, valueClass, initialValue).last();
		}
		
		/**
		 * @inheritDoc
		 */
		public function average():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(obs:IObserver):ICancelable
			{
				var total : Number = 0;
				var count : Number = 0;
				
				return source.subscribe(
					function(v:Number):void { count++; total += v; },
					function():void
					{
						if (count == 0)
						{
							obs.onError(new Error("Sequence contained no elements"));
						}
						else
						{
							obs.onNext(total / count);
							obs.onCompleted();
						}
					},
					obs.onError);
			});
			
			return aggregate(function(x:Number, y:Number):Number
			{
				return x+y;
			}, valueClass, 0);
		}
		
		/**
		 * @inheritDoc
		 */
		public function any(predicate : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			predicate = predicate || function(o:Object):Boolean { return true; }
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				return source.subscribe(
					function(pl : Object) : void
					{
						var result : Boolean = false;
						
						try
						{
							result = predicate(pl);
						}
						catch(error : Error)
						{
							observer.onError(error);
							return;
						}
						
						if (result)
						{
							observer.onNext(true);
							observer.onCompleted();
						}
					},
					function () : void
					{
						observer.onNext(false);
						observer.onCompleted();
					},
					observer.onError
					);
			});
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function all(predicate : Function) : IObservable
		{
			var source : IObservable = this;
			
			predicate = predicate || function(o:Object):Boolean { return true; }
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				return source.subscribe(
					function(pl : Object) : void
					{
						var result : Boolean = false;
						
						try
						{
							result = predicate(pl);
						}
						catch(error : Error)
						{
							observer.onError(error);
							return;
						}
						
						if (!result)
						{
							observer.onNext(false);
							observer.onCompleted();
						}
					},
					function () : void
					{
						observer.onNext(true);
						observer.onCompleted();
					},
					observer.onError
					);
			});
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function bufferWithCount(count:uint, skip:uint=0):IObservable
		{
			if (count == 0)
			{
				throw new ArgumentError("count must be > 0");
			}
			
			// skip == count and skip == 0 are functionally equivalent
			if (skip == count)
			{
				skip = 0;
			}
			
			var source : IObservable = this;

			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var buffer : Array = new Array();
				
				var valuesToSkip : uint = 0;
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						buffer.push(pl);
						
						while(buffer.length > 0 && valuesToSkip > 0)
						{
							buffer.shift();
							valuesToSkip--;
						}
						
						if (buffer.length == count)
						{
							observer.onNext(buffer);
							
							if (skip == 0)
							{
								buffer = [];
							}
							else
							{
								valuesToSkip = skip;
								
								while(buffer.length > 0 && valuesToSkip > 0)
								{
									buffer.shift();
									valuesToSkip--;
								}
							}
						}
					},
					function () : void
					{
						if (buffer.length > 0)
						{
							observer.onNext(buffer);
							buffer = [];
						}
						observer.onCompleted();
					},
					function (error : Error) : void
					{
						if (buffer.length > 0)
						{
							observer.onNext(buffer);
							buffer = [];
						}
						observer.onError(error);
					});
					
				return source.subscribeWith(dec);
			});
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function bufferWithTime(timeMs:uint, timeShiftMs:uint=0, scheduler:IScheduler=null):IObservable
		{
			if (timeMs == 0)
			{
				throw new ArgumentError("timeMs must be > 0");
			}
			
			// skip == count and skip == 0 are functionally equivalent
			if (timeShiftMs == timeMs)
			{
				timeShiftMs = 0;
			}
			
			var source : IObservable = this;
			
			scheduler = scheduler || Scheduler.synchronous;

			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var buffer : Array = new Array();
				var startTime : Number = scheduler.now.time;
				
				var flushBuffer : Function = function():void
				{
					var outBuffer : Array = new Array(buffer.length);
						
					for (var i:int=0; i<buffer.length; i++)
					{
						outBuffer[i] = buffer[i].value;
					}
					
					observer.onNext(outBuffer);
				};
				
				var intervalFunc : Function = function(i:int):void
				{
					flushBuffer();
					
					startTime += timeShiftMs;
					
					while(buffer.length > 0 && buffer[0].timestamp <= startTime)
					{
						buffer.shift();
					}
				};
				
				var intervalSubscription : ICancelable = Observable.interval(timeMs, scheduler)
					.subscribe(intervalFunc);
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						buffer.push(pl);
					},
					function () : void
					{
						flushBuffer();
						observer.onCompleted();
					},
					function (error : Error) : void
					{
						buffer = [];
						observer.onError(error);
					});
					
				var subscription : ICancelable = 
					source.timestamp(scheduler).subscribeWith(dec);
				
				return new ClosureCancelable(function():void 
				{
					subscription.cancel();
					intervalSubscription.cancel();
				});
			});
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function cast(valueClass : Class) : IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(valueClass, function(observer : IObserver) : ICancelable
			{
				return source.subscribe(
					function(x : Object) : void
					{
						if (x == null)
						{
							observer.onNext(x);
						}
						else
						{
							var obj : Object = x as valueClass;
							
							if (obj == null)
							{
								var fromClassName : String = getQualifiedClassName(x);
								var toClassName : String = getQualifiedClassName(valueClass);
								
								var error : Error = new TypeError(
									"Error #1034: Type Coercion failed: cannot convert " +
									fromClassName + " to " + toClassName
								); 
								
								observer.onError(error);
								return;
							}
							else
							{
								observer.onNext(obj);
							}
						}
					},
					observer.onCompleted,
					observer.onError);
			});
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function catchError(second : IObservable) : IObservable
		{
			return Observable.catchErrors([this, second]);
		}
		
		/**
		 * @inheritDoc
		 */
		public function catchErrorDefer(errorClass : Class, deferFunc : Function) : IObservable
		{
			var source : IObservable = this;
			
			if (deferFunc == null)
			{
				throw new ArgumentError("deferFunc");
			}
			
			errorClass = errorClass || Error;
			
			return new ClosureObservable(source.valueClass, function(obs:IObserver) : ICancelable
			{
				var subscription : ICancelable = null;
				
				subscription = source.subscribe(
					function(pl:Object) : void { obs.onNext(pl); },
					function() : void { obs.onCompleted(); },
					function(e : Error) : void
					{
						if (e is errorClass)
						{
							var catchObservable : IObservable = null;
							
							try
							{
								catchObservable = IObservable(deferFunc(e));
							}
							catch(funcErr : Error)
							{
								obs.onError(funcErr);
								return;
							}
							
							if (catchObservable == null)
							{
								obs.onError(e);
							}
							else
							{
								subscription = catchObservable.subscribeWith(obs);
							} 
						}
						else
						{
							obs.onError(e);
						}
					});
				
				return new ClosureCancelable(function():void
				{
					if (subscription != null)
					{
						subscription.cancel();
					}
				});
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function combineLatest(valueClass : Class, right:IObservable, selector:Function):IObservable
		{
			var left : IObservable = this;
			
			return new ClosureObservable(valueClass, function(observer : IObserver) : ICancelable 
			{
				var leftSubscription : FutureCancelable = new FutureCancelable();
				var leftValue : Object = null;
				var leftComplete : Object = null;
				var leftHasValue : Object = null;
				
				var rightSubscription : FutureCancelable = new FutureCancelable();
				var rightValue : Object = null;
				var rightComplete : Object = null;
				var rightHasValue : Object = null;				
				
				var subscriptions : CompositeCancelable = new CompositeCancelable(
					[leftSubscription, rightSubscription]);
				
				var checkValue : Function = function():void
				{
					if (leftHasValue && rightHasValue)
					{
						try
						{
							var value : Object = selector(leftValue, rightValue);
							observer.onNext(value);
						}
						catch(err : Error)
						{
							observer.onError(err);
						}
					}
				};
				
				var checkComplete : Function = function():void
				{
					if (leftComplete && rightComplete)
					{
						observer.onCompleted();
					}
				};
				
				Scheduler.immediate.schedule(function():void
				{
					leftSubscription.innerCancelable = left.subscribe(
						function(v:Object) : void
						{
							leftValue = v;
							leftHasValue = true;
							checkValue();
						},
						function():void { leftComplete = true; checkComplete(); },
						observer.onError);
					
					rightSubscription.innerCancelable = right.subscribe(
						function(v:Object) : void
						{
							rightValue = v;
							rightHasValue = true;
							checkValue();
						},
						function():void { rightComplete = true; checkComplete(); },
						observer.onError);
				});
				
				return subscriptions;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function concat(sources:Array):IObservable
		{
			sources = [this].concat(sources);
			
			return Observable.concat(this.valueClass, sources);
		}
		
		/**
		 * @inheritDoc
		 */
		public function contains(value : Object, comparer : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			comparer = (comparer == null)
				? defaultComparer
				: normalizeComparer(comparer);
			
			return new ClosureObservable(Boolean, function(observer : IObserver) : ICancelable
			{
				return source.subscribe(
					function(pl:Object) : void
					{
						var result : Boolean = false
						
						try
						{
							result = (comparer(pl, value) == true);
						}
						catch(err : Error)
						{
							observer.onError(err);
							return;
						}
						
						if (result)
						{
							observer.onNext(true);
							observer.onCompleted();
						}
					},
					
					function():void
					{
						observer.onNext(false);
						observer.onCompleted();
					},
					function(e : Error):void { observer.onError(e); }
				);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function count():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(uint, function(observer : IObserver):ICancelable
			{
				var count : uint = 0;
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						count++;
					},
					function () : void { observer.onNext(count); observer.onCompleted(); },
					observer.onError);
					
				return source.subscribeWith(dec);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function delay(delayMs:uint, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = scheduler || scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var scheduledActions : CompositeCancelable = new CompositeCancelable([]);
				var nextScheduledAction : ICancelable = null;
				var completeScheduledAction : ICancelable = null;
				
				var future : FutureCancelable = new FutureCancelable();
				
				var composite : ICancelable = new CompositeCancelable([scheduledActions, future]);
				
				future.innerCancelable = source.subscribe(
					function(pl : Object) : void
					{
						scheduledActions.add(scheduler.schedule(function():void { observer.onNext(pl); }, delayMs));
					},
					function () : void
					{
						scheduledActions.add(scheduler.schedule(function():void { observer.onCompleted(); }, delayMs));
					},
					function (error : Error) : void
					{
						scheduledActions.cancel();
						
						observer.onError(error);
					}
					);
					
				return composite;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function delayUntil(dt:Date, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			var dtValue : Number = dt.time;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				scheduler = scheduler || scheduler || Scheduler.synchronous;
				
				var isPastDate : Boolean = (scheduler.now.time >= dtValue);
				var scheduledActions : CompositeCancelable = new CompositeCancelable([]);
				
				var future : FutureCancelable = new FutureCancelable();
				scheduledActions.add(future);				
				
				future.innerCancelable = source.materialize().subscribe(
					function(pl : Notification) : void
					{
						var now : Number = 0;
						
						if (!isPastDate)
						{
							now = scheduler.now.time;
							
							if (now >= dtValue)
							{							
								isPastDate = true;
							}
						}
						
						if (isPastDate)
						{
							scheduledActions.add(
								scheduler.schedule(function():void { pl.acceptWith(observer); })
							);
						}
						else
						{
							var delayMs : Number = dtValue - now;
							
							scheduledActions.push( 
								scheduler.schedule(function():void { pl.acceptWith(observer); }, delayMs)
							);
						}
					}
					);
					
				return scheduledActions;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function dematerialize(valueClass : Class):IObservable
		{
			var source : IObservable = this;
			
			if (source.valueClass != Notification)
			{
				throw new ArgumentError("dematerialize can only be called on IObservable of " +
					"Notification, which is returned by materialize");
			}
			
			return new ClosureObservable(valueClass, function(observer : IObserver):ICancelable
			{
				return source.subscribe(
					function(pl : Notification) : void { pl.acceptWith(observer); }
				);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function doAction(nextAction:Function, completeAction:Function = null, errorAction:Function = null):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						try
						{
							if (nextAction != null) nextAction(pl);
						}
						catch(err : Error)
						{
							observer.onError(err);
							return;
						}
						
						observer.onNext(pl);
						
					},
					function () : void
					{
						if (completeAction != null)
						{
							completeAction();
						}
						
						observer.onCompleted();
					},
					function (error : Error) : void
					{
						if (errorAction != null)
						{
							errorAction(error);
						}
						
						observer.onError(error);
					});
					
				return source.subscribeWith(dec);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function finallyAction(action:Function):IObservable
		{
			if (action == null) throw new ArgumentError("finallyAction");
			
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var subscription : ICancelable = source.subscribeWith(observer);
				
				return new ClosureCancelable(function():void
				{
					try
					{
						subscription.cancel()						
					}
					finally
					{
						action();
					}
				});
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function first():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						observer.onNext(pl);
						observer.onCompleted();
					},
					function () : void { observer.onError(new Error("The sequence contained no values")); },
					observer.onError);
					
				return source.subscribeWith(dec);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function firstOrDefault():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						observer.onNext(pl);
						observer.onCompleted();
					},
					function () : void
					{
						observer.onNext(null);
						observer.onCompleted();
					},
					observer.onError);
					
				return source.subscribeWith(dec);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function forkJoin(resultClass : Class, right : IObservable, selector : Function):IObservable
		{
			return this.combineLatest(resultClass, right, selector).takeLast(1);
		}
		
		/**
		 * @inheritDoc
		 */
		public function join(right : IObservable, 
			leftWindowSelector : Function, rightWindowSelector : Function, 
			resultClass : Class, joinSelector : Function) : IObservable
		{
			var source : IObservable = this;
			
			return Observable.createWithCancelable(resultClass, function(observer:IObserver) : ICancelable
			{
				return source.groupJoin(right, leftWindowSelector, rightWindowSelector, Object, function(leftValue:Object, joinedRightValues:IObservable) : Object
				{
					// TODO: Should we bother track subscriptions here? groupJoin should avoid any memleaks
					return joinedRightValues.subscribe(function(rightValue:Object) : void
						{
							var resultValue : Object;
							
							try
							{
								resultValue = joinSelector(leftValue, rightValue);
							}
							catch(error : Error)
							{
								observer.onError(error);
								return;
							}
							
							observer.onNext(resultValue);
						});
				})
				.ignoreValues()
				.subscribeWith(observer);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function groupJoin(right : IObservable, 
			leftWindowSelector : Function, rightWindowSelector : Function, 
			resultClass : Class, joinSelector : Function) : IObservable
		{
			var source : IObservable = this;
			
			return Observable.createWithCancelable(resultClass, function(observer:IObserver) : ICancelable
			{
				var leftSubscription : FutureCancelable = new FutureCancelable();
				var rightSubscription : FutureCancelable = new FutureCancelable();
				
				var windowSubscriptions : CompositeCancelable = new CompositeCancelable();
				var rightWindowSubscriptions : CompositeCancelable = new CompositeCancelable();
				
				var activeLeftSubjects : Array = new Array();
				var activeRightValues : Dictionary = new Dictionary();
				var activeRightValuesCount : int = 0;
				var rightID : int = int.MIN_VALUE;
				
				var subscription : CompositeCancelable = new CompositeCancelable([
					leftSubscription, rightSubscription, windowSubscriptions, rightWindowSubscriptions]);
				
				var leftComplete : Boolean = false;
				var rightComplete : Boolean = false;
				
				leftSubscription.innerCancelable = source
					.subscribe(function(leftValue : Object) : void
					{
						var leftWindow : IObservable;
						var rightValuesSubject : Subject = new Subject(right.valueClass);
						var returnValue : Object;
						
						try
						{
							leftWindow = IObservable(leftWindowSelector(leftValue));
							
							returnValue = joinSelector(leftValue, rightValuesSubject.asObservable());
						}
						catch(error : Error)
						{
							// TODO
							
							observer.onError(error);
							return;
						}
						
						observer.onNext(returnValue);
						
						for each(var activeRightValue : Object in activeRightValues)
						{
							rightValuesSubject.onNext(activeRightValue);
						}
						
						var windowSubscription : FutureCancelable = new FutureCancelable();
						windowSubscriptions.add(windowSubscription);
						
						activeLeftSubjects.push(rightValuesSubject);
							
						windowSubscription.innerCancelable = leftWindow.take(1)
							.subscribe(null, function():void
							{
								rightValuesSubject.onCompleted();
								activeLeftSubjects.splice(activeLeftSubjects.indexOf(rightValuesSubject), 1);
								windowSubscriptions.remove(windowSubscription);
								
								if (leftComplete && activeLeftSubjects.length == 0)
								{
									observer.onCompleted();
								}
								
							}, function(e:Error) : void
							{
								// TODO
								
								activeLeftSubjects.splice(activeLeftSubjects.indexOf(rightValuesSubject), 1);
								windowSubscriptions.remove(windowSubscription);
								observer.onError(e);
							});
					},
					function():void
					{
						leftComplete = true;
						
						if (rightComplete || activeLeftSubjects.length == 0)
						{
							observer.onCompleted();
						}
					});
					
				rightSubscription.innerCancelable = right.subscribe(
					function(rightValue : Object) : void
					{
						var rightWindow : IObservable;
						var activeRightValueID : int = rightID++;
						
						for each(var subject : Subject in activeLeftSubjects)
						{
							subject.onNext(rightValue);
						} 
						
						try
						{
							rightWindow = IObservable(rightWindowSelector(rightWindow));
						}
						catch(error : Error)
						{
							// TODO
							
							observer.onError(error);
							return;
						}
						
						activeRightValues[activeRightValueID] = rightValue;
						activeRightValuesCount++;
						
						var windowSubscription : FutureCancelable = new FutureCancelable();
						windowSubscriptions.add(windowSubscription);
						
						windowSubscription.innerCancelable = rightWindow.take(1)
							.subscribe(null, function():void
							{
								delete activeRightValues[activeRightValueID];
								activeRightValuesCount--;
								rightWindowSubscriptions.remove(windowSubscription);
								
								if (rightComplete && activeRightValuesCount == 0)
								{
									for each(var activeSubject : Subject in activeLeftSubjects)
									{
										activeSubject.onCompleted();
									}
									
									observer.onCompleted();
								}
							}, function(e:Error) : void
							{
								// TODO
								
								delete activeRightValues[activeRightValueID];
								activeRightValuesCount--;
								rightWindowSubscriptions.remove(windowSubscription);
								observer.onError(e);
							});
					},
					function() : void
					{
						rightComplete = true;
						
						if ((leftComplete && activeLeftSubjects.length == 0) || activeRightValuesCount == 0)
						{
							for each(var activeSubject : Subject in activeLeftSubjects)
							{
								activeSubject.onCompleted();
							}
							
							observer.onCompleted();
						}
					});
					
				return subscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function groupBy(elementClass : Class, keySelector : Function, elementSelector : Function = null, 
			keyComparer : Function = null) : IObservable
		{
			return groupByUntil(elementClass, keySelector, 
				function(groupedObservable : IGroupedObservable) : IObservable
				{
					return Observable.never(Object);
				},
				elementSelector, keyComparer);
		}
		
		public function groupByUntil(elementClass : Class, keySelector : Function, durationSelector : Function, elementSelector : Function = null,  keyComparer : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			keyComparer = (keyComparer == null)
				? defaultComparer
				: normalizeComparer(keyComparer);
				
			elementSelector = (elementSelector == null)
				? function(x:Object) : Object { return x; }
				: elementSelector;
			
			return Observable.createWithCancelable(IGroupedObservable, function(observer : IObserver) : ICancelable
			{
				var activeGroupKeys : Array = new Array();
				var activeGroupSubjects : Array = new Array();
				
				var onError : Function = function(error : Error) : void
				{
					for each(var activeGroupSubject : Subject in activeGroupSubjects)
					{
						activeGroupSubject.onError(error);
					}
					
					observer.onError(error);
				};
				
				var findKey : Function = function(key : Object) : int
				{
					for (var i:int=0; i<activeGroupKeys.length; i++)
					{
						if (keyComparer(activeGroupKeys[i], key))
						{
							return i;
						}
					}
					
					return -1;
				};
				
				var sourceSubscription : FutureCancelable = new FutureCancelable();
				var durationSubscriptions : CompositeCancelable = new CompositeCancelable();
				
				sourceSubscription.innerCancelable = source.subscribe(
					function(sourceValue : Object) : void
					{
						var key : Object;
						var element : Object;
						var keyIndex : int = -1;
						
						try
						{
							key = keySelector(sourceValue);
							element = elementSelector(sourceValue);
							
							keyIndex = findKey(key);
						}
						catch(error : Error)
						{
							onError(error);
							return;
						}
						
						var groupSubject : Subject = null;
						
						if (keyIndex != -1)
						{
							groupSubject = activeGroupSubjects[keyIndex] as Subject;
							
							groupSubject.onNext(element);
						}
						else
						{
							groupSubject = new Subject(elementClass);
							
							activeGroupKeys.push(key);
							activeGroupSubjects.push(groupSubject);
							
							var group : IGroupedObservable = new GroupedObservable(key, groupSubject);
							
							var groupDuration : IObservable;
							
							try
							{
								groupDuration = IObservable(durationSelector(group));
							}
							catch(error : Error)
							{
								onError(error);
								return;
							}
							
							var durationSubscription : FutureCancelable = new FutureCancelable();

						    durationSubscriptions.add(durationSubscription);
						    
						    observer.onNext(group);
						    groupSubject.onNext(element);
							
							durationSubscription.innerCancelable = groupDuration
								//.take(1).ignoreValues().subscribe(null, function():void
								.take(1).subscribe(null, function():void
								{
									var keyIndex : int = -1;
									
									try
									{
										keyIndex = findKey(key);
									}
									catch(error : Error)
									{
										onError(error);
										return;
									}
									
									durationSubscriptions.remove(durationSubscription);
									groupSubject.onCompleted();
									activeGroupKeys.splice(keyIndex, 1);
									activeGroupSubjects.splice(keyIndex, 1);
								});
						}
					}, observer.onCompleted, onError);
					
				return new CompositeCancelable([sourceSubscription, durationSubscriptions]);
			});
		}
		 
		/**
		 * @inheritDoc
		 */
		public function asObservable():IObservable
		{
			var source : IObservable = this;
			
			return Observable.defer(source.valueClass, function():IObservable
			{
				return source;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function ignoreValues() : IObservable
		{
			var source : IObservable = this;
			
			return Observable.createWithCancelable(this.valueClass, function(observer : IObserver) : ICancelable
			{
				return source.subscribe(null, observer.onCompleted, observer.onError); 
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function distinctUntilChanged(comparer:Function = null):IObservable
		{
			var source : IObservable = this;
			
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			comparer = (comparer == null)
				? defaultComparer
				: normalizeComparer(comparer);
			
			return new ClosureObservable(Boolean, function(observer : IObserver) : ICancelable
			{
				var lastValue : Object = null;
				var hasValue : Boolean = false;
				
				return source.subscribe(
					function(pl:Object) : void
					{
						var result : Boolean = false
						
						try
						{
							result = (comparer(lastValue, pl) == true);
						}
						catch(err : Error)
						{
							observer.onError(err);
							return;
						}
						
						if (!(result && hasValue))
						{
							hasValue = true;
							lastValue = pl;
							
							observer.onNext(pl);
						}
					},
					
					observer.onCompleted,
					observer.onError
				);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function last():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var lastValue : Object = null;
				var hasValue : Boolean = false;
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						lastValue = pl;
						hasValue = true;
					},
					function () : void
					{
						if (hasValue)
						{
							observer.onNext(lastValue);
							observer.onCompleted();
						}
						else
						{
							observer.onError(new Error("The sequence contained no values"));
						}
					},
					observer.onError);
					
				return source.subscribeWith(dec);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function lastOrDefault():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var lastValue : Object = null;
				var hasValue : Boolean = false;
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						lastValue = pl;
						hasValue = true;
					},
					function () : void
					{
						if (hasValue)
						{
							observer.onNext(lastValue);
						}
						else
						{
							observer.onNext(null);
						}
						
						observer.onCompleted();
					},
					observer.onError);
					
				return source.subscribeWith(dec);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function let(func : Function) : IObservable
		{
			return IObservable(func(this));
		}
		
		/**
		 * @inheritDoc
		 */
		public function materialize():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(Notification, function(observer : IObserver):ICancelable
			{
				return source.subscribe(
					function(pl : Object) : void { observer.onNext(new OnNext(pl)); },
					function () : void { observer.onNext(new OnCompleted()); observer.onCompleted(); },
					function (error : Error) : void { observer.onNext(new OnError(error)); observer.onCompleted(); }
				);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function merge(sources : IObservable, scheduler:IScheduler=null):IObservable
		{
			return Observable.mergeMany(this.valueClass, sources.startWith([this], scheduler), scheduler);
		}
		
		/**
		 * @inheritDoc
		 */
		public function ofClass(valueClass : Class) : IObservable
		{
			return this.filter(function(x:Object):Boolean
			{
				return x is valueClass;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function observeOn(scheduler:IScheduler):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var scheduledAction : FutureCancelable = new FutureCancelable();
				
				var subscription : ICancelable = source.materialize()
					.subscribe(function(n:Notification):void
					{
						scheduledAction.innerCancelable = scheduler.schedule(function():void
						{
							n.acceptWith(observer);
						});
					});

				return new CompositeCancelable([subscription, scheduledAction]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function subscribeOn(scheduler:IScheduler):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var first : FutureCancelable = new FutureCancelable();
				var second : FutureCancelable = new FutureCancelable();
				
				first.innerCancelable = scheduler.schedule(function():void
				{
					second.innerCancelable = source.subscribeWith(observer);
				});
				
				return new CompositeCancelable([first, second]);
			});
		}
				
		/**
		 * @inheritDoc
		 */
		public function onErrorResumeNext(second:IObservable, scheduler:IScheduler=null):IObservable
		{
			return Observable.onErrorResumeNext([this, second], scheduler);
		}
		
		/**
		 * @inheritDoc
		 */
		public function prune(scheduler : IScheduler = null) : IConnectableObservable
		{
			return multicast(new AsyncSubject(this.valueClass, scheduler));
		}
		
		/**
		 * @inheritDoc
		 */
		public function pruneAndConnect(selector : Function, scheduler : IScheduler = null) : IObservable
		{
			var valueClass : Class = this.valueClass;
			
			return multicastAndConnect(
				function():ISubject { return new AsyncSubject(valueClass, scheduler); },
				selector
			);
		}
		
		/**
		 * @inheritDoc
		 */
		public function publish() : IConnectableObservable
		{
			return multicast(new Subject(this.valueClass));
		}
		
		/**
		 * @inheritDoc
		 */
		public function publishAndConnect(selector : Function) : IObservable
		{
			var valueClass : Class = this.valueClass;
			
			return multicastAndConnect(
				function():ISubject { return new Subject(valueClass); },
				selector
			);
		}
		
		/**
		 * @inheritDoc
		 */
		public function multicast(subject : ISubject) : IConnectableObservable
		{
			return new ConnectableObservable(this, subject);
		}
		
		/**
		 * @inheritDoc
		 */
		public function multicastAndConnect(subjectSelector : Function, selector : Function) : IObservable
		{
			return new ClosureObservable(this.valueClass, function(obs:IObserver):ICancelable
			{
				var subject : ISubject = subjectSelector();
				var connectable : IConnectableObservable = multicast(subject);
				
				return new CompositeCancelable([
					IObservable(selector(connectable)).subscribeWith(obs),
					connectable.connect()
				]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function queued(queue : IObserver) : IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer:IObserver):ICancelable
			{
				var queueCancelable : BooleanCancelable = new BooleanCancelable();
				var sourceCancelable : FutureCancelable = new FutureCancelable();
				
				queue.onNext(new ClosureObservable(source.valueClass, function(queueObserver:IObserver):ICancelable
				{
					if (queueCancelable.isCanceled)
					{
						queueObserver.onCompleted();
						return Cancelable.empty;
					}
					
					sourceCancelable.innerCancelable = source
					.finallyAction(function():void
					{
						queueObserver.onCompleted();
					})
					.subscribeWith(observer);
					
					return sourceCancelable;
				}));
				
				return new CompositeCancelable([queueCancelable, sourceCancelable]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeTimeInterval(valueClass : Class) : IObservable
		{
			if (this.valueClass != TimeInterval)
			{
				throw new IllegalOperationError("Cannot remove timeInterval from observable that is of type " +
					getQualifiedClassName(this.valueClass));
			}
			
			return this.map(valueClass, function(ts:TimeInterval):Object
			{
				return ts.value;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeTimestamp(valueClass : Class) : IObservable
		{
			if (this.valueClass != TimeStamped)
			{
				throw new IllegalOperationError("Cannot remove timestamp from observable that is of type " +
					getQualifiedClassName(this.valueClass));
			}
			
			return this.map(valueClass, function(ts:TimeStamped):Object
			{
				return ts.value;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function replay(bufferSize : uint = 0, window : uint = 0, 
			scheduler : IScheduler = null) : IConnectableObservable
		{
			return multicast(new ReplaySubject(this.valueClass, bufferSize, window, scheduler));
		}
		
		/**
		 * @inheritDoc
		 */
		public function replayAndConnect(selector : Function, bufferSize : uint = 0, window : uint = 0, 
			scheduler : IScheduler = null) : IObservable
		{
			var valueClass : Class = this.valueClass;
			
			return multicastAndConnect(
				function():ISubject { return new ReplaySubject(this.valueClass, bufferSize, window, scheduler); },
				selector
			);
		}
		
		/**
		 * @inheritDoc
		 */
		public function repeat(repeatCount:uint=0):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var isInfinite : Boolean = (repeatCount == 0);
				var iterationsRemaining : int = repeatCount - 1;
				
				var subscription : FutureCancelable = new FutureCancelable();				
				var recursiveObserver : IObserver = null;
				
				recursiveObserver = new ClosureObserver(
					function(pl:Object) : void { observer.onNext(pl); },
					function():void
					{
						if (isInfinite || iterationsRemaining-- > 0)
						{
							Scheduler.immediate.schedule(function():void
							{
								subscription.innerCancelable = source.subscribeWith(recursiveObserver);
							});
						}
						else
						{
							observer.onCompleted();
						}
					},
					observer.onError);
				
				Scheduler.immediate.schedule(function():void
				{
					subscription.innerCancelable = source.subscribeWith(recursiveObserver);
				});
				
				return subscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function retry(retryCount:uint = 0):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var isInfinite : Boolean = (retryCount == 0);
				var iterationsRemaining : int = retryCount - 1;
				
				var subscription : FutureCancelable = new FutureCancelable();				
				var recursiveObserver : IObserver = null;
				
				recursiveObserver = new ClosureObserver(
					function(pl:Object) : void { observer.onNext(pl); },
					observer.onCompleted,
					function(err : Error):void
					{
						if (isInfinite || iterationsRemaining-- > 0)
						{
							Scheduler.immediate.schedule(function():void
							{
								subscription.innerCancelable = source.subscribeWith(recursiveObserver);
							});
						}
						else
						{
							observer.onError(err);
						}
					});
				
				Scheduler.immediate.schedule(function():void
				{
					subscription.innerCancelable = source.subscribeWith(recursiveObserver);
				});
				
				return subscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function sample(intervalMs : uint, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			var source : IObservable = this;
			
			return new ClosureObservable(this.valueClass, function(observer : IObserver) : ICancelable
			{
				var subscription : CompositeCancelable = new CompositeCancelable([]);
				
				var isComplete : Boolean = false;
				var valueChanged : Boolean = false;
				var value : Object = null;
				
				subscription.add(Observable.interval(intervalMs, scheduler).subscribe(
					function(i:int):void
					{
						if (valueChanged)
						{
							observer.onNext(value);
							valueChanged = false;
						}
						
						if (isComplete)
						{
							observer.onCompleted();
						}
					}));
					
				subscription.add(source.subscribe(
					function(v:Object):void
					{
						valueChanged = true;
						value = v;
					},
					function():void
					{
						isComplete = true;
					},
					observer.onError));
					
				return subscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function scan(accumulator : Function, valueClass : Class = null, initialValue : Object = null) : IObservable
		{
			var useInitialValue : Boolean = (valueClass != null);
			
			if (!useInitialValue)
			{
				valueClass = this.valueClass; 
			}
			
			var source : IObservable = this;
			
			return Observable.defer(valueClass, function():IObservable
			{
				var skipFirst : Boolean = true;
				var accumulatedValue : Object = null;
				
				if (useInitialValue)
				{
					skipFirst = false;
					accumulatedValue = initialValue;
				}
				
				return source.map(valueClass, function(value:Object):Object
				{
					if (skipFirst) 
					{
						skipFirst = false;
						
						accumulatedValue = value;
					}
					else
					{
						accumulatedValue = accumulator(accumulatedValue, value);
					}
					
					return accumulatedValue;
				});
			});
			
			return new ClosureObservable(valueClass, function(obs:IObserver):ICancelable
			{
				var aggregate : Object = null;
				
				return 
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function map(valueClass : Class, selector:Function):IObservable
		{
			return mapInternal(valueClass, selector);
		}
		
		/**
		 * @inheritDoc
		 */
		[Deprecated(replacement="map")]
		public function select(valueClass : Class, selector:Function):IObservable
		{
			return map(valueClass, selector);
		}
		
		private function mapInternal(valueClass : Class, selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(valueClass, function (observer : IObserver) : ICancelable
			{
				var subscription : FutureCancelable = new FutureCancelable();
				
				subscription.innerCancelable = source.subscribe(
					function (value : Object) : void
					{
						try
						{
							value = selector(value);
						}
						catch(err : Error)
						{
							observer.onError(err);
							return;
						}
						
						observer.onNext(value);
					},
					observer.onCompleted,
					observer.onError
					);
				
				return subscription;
			});
		}
		
		[Deprecated(replacement="mapMany")]
		/**
		 * @inheritDoc
		 */
		public function selectMany(valueClass : Class, selector:Function):IObservable
		{
			return mapMany(valueClass, selector);
		}
		
		/**
		 * @inheritDoc
		 */
		public function mapMany(valueClass : Class, selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return Observable.mergeMany(valueClass, this.map(IObservable, selector)); 
		}
		
		/**
		 * @inheritDoc
		 */
		public function single():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var hasValue : Boolean = false;
				var value : Object = null;
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						if (hasValue)
						{
							observer.onError(new Error("The sequence contained more than one value"));
						}
						else
						{
							value = pl;
							hasValue = true;
						}
					},
					function () : void
					{
						if (hasValue)
						{
							observer.onNext(value);
							observer.onCompleted();
						}
						else
						{
							observer.onError(new Error("The sequence contained no values"));
						}
					},
					observer.onError);
					
				return source.subscribeWith(dec);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function singleOrDefault():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var hasValue : Boolean = false;
				var value : Object = null;
				
				return source.subscribe(
					function(pl : Object) : void
					{
						if (hasValue)
						{
							observer.onError(new Error("The sequence contained more than one value"));
						}
						else
						{
							value = pl;
							hasValue = true;
						}
					},
					function () : void
					{
						observer.onNext(value);
						observer.onCompleted();
					},
					observer.onError);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function skip(count:uint):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var skippedSoFar : uint = 0;
				
				var subscription : ICancelable;
				
				return source.subscribe(
					function (value : Object) : void
					{
						if (++skippedSoFar > count)
						{
							observer.onNext(value);
						}
					},
					observer.onCompleted,
					observer.onError
					);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function skipLast(count : uint) : IObservable
		{
			if (count == 0)
			{
				throw new ArgumentError("count cannot be 0");
			}
			
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var buffer : Array = new Array();
				
				var futureSubscription : FutureCancelable = new FutureCancelable();
				
				futureSubscription.innerCancelable = source.subscribe(
					function(v:Object):void
					{
						buffer.push(v);
					},
					function():void
					{
						while(buffer.length > count)
						{
							observer.onNext(buffer.shift());
						}
						
						observer.onCompleted();
					},
					observer.onError);
					
				return futureSubscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function skipUntil(other:IObservable):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var subscription : ICancelable;
				
				var pastSkip : Boolean = false;
				
				var primarySubscription : ICancelable;
				var otherSubscription : ICancelable;
				
				primarySubscription = source.subscribe(
					function (value : Object) : void
					{
						if (pastSkip)
						{
							observer.onNext(value);
						}
					},
					observer.onCompleted,
					observer.onError
					);
					
				otherSubscription = other.subscribe(
					function (value : Object) : void
					{
						pastSkip = true;
						if (otherSubscription != null)
						{
							otherSubscription.cancel();
						}
					},
					function () : void  { },
					observer.onError
					);
				
				if (pastSkip)
				{
					otherSubscription.cancel();
					otherSubscription = null;
				}
				
				return new ClosureCancelable(function():void
				{
					if (primarySubscription != null)
					{
						primarySubscription.cancel();
					}
					
					if (otherSubscription != null)
					{
						otherSubscription.cancel();
					}
				});
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function skipWhile(predicate:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var skipping : Boolean = true;
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						if (skipping)
						{
							try
							{
								skipping &= predicate(value);
							}
							catch(err : Error)
							{
								observer.onError(err);
							}
						}
						
						if (!skipping)
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
		
		/**
		 * @inheritDoc
		 */
		public function startWith(values : Array, scheduler : IScheduler = null) : IObservable
		{
			return Observable
				.fromArray(this.valueClass, values, scheduler)
				.concat([this]);
		}
		
		/**
		 * @inheritDoc
		 */
		public function switchMany(valueClass : Class, selector : Function) : IObservable
		{
			var source : IObservable = this.map(IObservable, selector);
			
			return new ClosureObservable(valueClass, function(observer : IObserver) : ICancelable
			{
				var parentCancelable : FutureCancelable = new FutureCancelable();
				var parentCompleted : Boolean = false;
				
				var childCancelable : FutureCancelable = new FutureCancelable();
				var childCompleted : Boolean = false;
				
				parentCancelable.innerCancelable = source.subscribe(
					function(child : IObservable) : void
					{
						childCancelable.innerCancelable = child.subscribe(
							observer.onNext,
							function() : void 
							{
								childCompleted = true;
						
								if (parentCompleted)
								{
									observer.onCompleted();
								}
							},
							observer.onError);
					},
					function() : void
					{
						parentCompleted = true;
						
						if (childCompleted)
						{
							observer.onCompleted();
						}
					},
					observer.onError);
				
				
				return new CompositeCancelable([childCancelable, parentCancelable]);
			});
		}

		/**
		 * @inheritDoc
		 */
		public function sum():IObservable
		{
			return aggregate(function(x:Number, y:Number):Number
			{
				return x+y;
			}, valueClass, 0).catchError(Observable.returnValue(valueClass, 0));
		}
		
		/**
		 * @inheritDoc
		 */
		public function take(count:uint):IObservable
		{
			var source : IObservable = this;
			
			if (count == 0)
			{
				return Observable.empty(this.valueClass); 
			}
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var countSoFar : uint = 0;
				
				var subscription : FutureCancelable = new FutureCancelable();
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						observer.onNext(value);
						
						if (++countSoFar == count)
						{
							observer.onCompleted();
						}
					},
					observer.onCompleted,
					observer.onError
					);
				
				subscription.innerCancelable = source.subscribeWith(decoratorObserver);
				
				return subscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function takeLast(count : uint) : IObservable
		{
			if (count == 0)
			{
				throw new ArgumentError("count cannot be 0");
			}
			
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var buffer : Array = new Array();
				
				var futureSubscription : FutureCancelable = new FutureCancelable();
				
				futureSubscription.innerCancelable = source.subscribe(
					function(v:Object):void
					{
						buffer.push(v);
						
						if (buffer.length > count)
						{
							buffer.shift();
						}
					},
					function():void
					{
						while(buffer.length > 0)
						{
							observer.onNext(buffer.shift());
						}
						observer.onCompleted();
					},
					observer.onError);
					
				return futureSubscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function takeUntil(other:IObservable):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var subscription : ICancelable;
				
				var primarySubscription : FutureCancelable = new FutureCancelable();
				var otherSubscription : FutureCancelable = new FutureCancelable();
				
				var composite : ICancelable = new CompositeCancelable([
					primarySubscription, otherSubscription
				]);
				
				otherSubscription.innerCancelable = other.subscribe(
					function (value : Object) : void { observer.onCompleted(); },
					observer.onCompleted,
					observer.onError
					);
					
				primarySubscription.innerCancelable = source.subscribeWith(observer);
					
				
				return composite;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function takeWhile(predicate:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				return source.subscribe(
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
							return;
						}
							
						if (result)
						{
							observer.onNext(value);
						}
						else
						{
							observer.onCompleted();
						}
					},
					observer.onCompleted,
					observer.onError
					);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function then(type : Class, thenFunction : Function) : Plan
		{
			return new Plan(type, [this], thenFunction);
		}
		
		/**
		 * @inheritDoc
		 */
		public function throttle(dueTimeMs:uint, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var lastValueTimestamp : Number = 0;
				
				var subscription : ICancelable;
				
				return source.timestamp(scheduler).subscribe(
					function (value : TimeStamped) : void
					{
						var diffMs : Number = value.timestamp - lastValueTimestamp;
						
						if (diffMs > dueTimeMs)
						{
							lastValueTimestamp = value.timestamp;
							
							observer.onNext(value.value);
						}
					},
					observer.onCompleted,
					observer.onError
					);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function timeInterval(scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(TimeInterval, function (observer : IObserver) : ICancelable
			{
				var lastTimeMs : Number = -1;
				
				return source.subscribe(
					function (value : Object) : void
					{
						var now : Number = (scheduler.now).time;
						var interval : Number = (lastTimeMs == -1)
							? 0
							: now - lastTimeMs;
							
						lastTimeMs = now;
							
						var intervalValue : TimeInterval = new TimeInterval(value, interval);
							
						scheduler.schedule(
							function():void { observer.onNext(intervalValue); });
					},
					observer.onCompleted,
					observer.onError
					);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function timeout(timeoutMs:uint, other:IObservable=null, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			other = other || Observable.throwError(new TimeoutError("Sequence timed out"), this.valueClass);
			
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
			{
				var timeout : FutureCancelable = new FutureCancelable();
				var subscription : FutureCancelable = new FutureCancelable();
				
				var composite : ICancelable = new CompositeCancelable([timeout, subscription]);
				
				timeout.innerCancelable = scheduler.schedule(function():void
				{
					subscription.cancel();
					subscription = other.subscribeWith(observer);
				}, timeoutMs);
				
				subscription.innerCancelable = source.subscribe(
					function (value : Object) : void
					{
						timeout.cancel();
						
						observer.onNext(value);
					},
					function () : void
					{
						timeout.cancel();
						observer.onCompleted();
					},
					observer.onError
					);
				
				return composite;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function timestamp(scheduler:IScheduler=null):IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			return mapInternal(TimeStamped, function(value : Object) : TimeStamped
			{
				return new TimeStamped(value, scheduler.now.time);
			});
		}
		
		[Deprecated(replacement="filter")]
		/**
		 * @inheritDoc
		 */
		public function where(predicate:Function):IObservable
		{
			return filter(predicate);
		}
		
		/**
		 * @inheritDoc
		 */
		public function filter(predicate:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function (observer : IObserver) : ICancelable
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
		
		/**
		 * @inheritDoc
		 */
		public function zip(valueClass : Class, rightSource:IObservable, selector:Function):IObservable
		{
			// TODO: Could this be replaced with a single-plan join?
			
			var source : IObservable = this;
			
			return new ClosureObservable(valueClass, function (observer : IObserver) : ICancelable
			{
				var canceled : Boolean = false;
				
				var leftComplete : Boolean = false;
				var leftValues : Array = new Array();
				
				var rightComplete : Boolean = false;
				var rightValues : Array = new Array();
				
				var leftSubscription : FutureCancelable = new FutureCancelable(), 
					rightSubscription : FutureCancelable = new FutureCancelable();
				
				var leftObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						if (rightValues.length > 0)
						{
							value = selector(value, rightValues.shift());
							
							observer.onNext(value);
						}
						else
						{
							leftValues.push(value);
						}
					},
					function():void
					{
						leftComplete = true; 
						if (rightComplete) { observer.onCompleted(); }
					},
					observer.onError
					);
					
				var rightObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						if (leftValues.length > 0)
						{
							value = selector(leftValues.shift(), value);
							
							observer.onNext(value);
						}
						else
						{
							rightValues.push(value);
						}
					},
					function():void
					{
						rightComplete = true; 
						if (leftComplete) { observer.onCompleted(); }
					},
					observer.onError
					);
					
				leftSubscription.innerCancelable = source.subscribeWith(leftObserver);
				rightSubscription.innerCancelable = rightSource.subscribeWith(rightObserver);
				
				return new ClosureCancelable(function():void
				{
					new CompositeCancelable([leftSubscription, rightSubscription]).cancel();
				});
			});
		}
		
		private static function normalizeComparer(source : Function) : Function
		{
			return function(a:Object,b:Object) : Boolean
			{
				var result : Object = source(a, b);
				
				if (result is Boolean)
				{
					return (result == true);
				}
				
				if (result is int || result is Number || result is uint)
				{
					return (result == 0);
				}
				
				throw new ArgumentError("comparer function must return Boolean or int");
			};
		}		
	}
}