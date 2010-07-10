package rx
{
	import flash.errors.IllegalOperationError;
	import flash.utils.getQualifiedClassName;
	
	import rx.*;
	import rx.scheduling.*;
	import rx.subjects.AsyncSubject;
	import rx.subjects.ConnectableObservable;
	import rx.subjects.IConnectableObservable;
	import rx.subjects.ReplaySubject;
	import rx.util.*;
	
	public class AbsObservable implements IObservable
	{
		public function AbsObservable()
		{
		}
		
		public function get valueClass() : Class
		{
			return Object;
		}
		
		public function subscribeWith(observer : IObserver) : ICancelable
		{
			// Abstract methods not supported by AS3
			throw new IllegalOperationError("subscribe() must be overriden");
		}
		
		public function subscribe(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : ICancelable
		{
			var observer : IObserver = new ClosureObserver(onNext, onComplete, onError);
			
			return subscribeWith(observer);
		}
		
		public function and(right : IObservable) : Pattern
		{
			return new Pattern([this, right]);
		}

		public function aggregate(accumulator : Function, outputType : Class = null, initialValue : Object = null) : IObservable
		{
			return scan(accumulator, outputType, initialValue).last();
		}
		
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
		
		public function cast(type : Class) : IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(type, function(observer : IObserver) : ICancelable
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
							var obj : Object = x as type;
							
							if (obj == null)
							{
								var fromType : String = getQualifiedClassName(x);
								var toType : String = getQualifiedClassName(type);
								
								var error : Error = new TypeError(
									"Error #1034: Type Coercion failed: cannot convert " +
									fromType + " to " + toType
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
		
		public function catchError(second : IObservable) : IObservable
		{
			return Observable.catchErrors([this, second]);
		}
		
		public function catchErrorDefer(errorType : Class, deferFunc : Function) : IObservable
		{
			var source : IObservable = this;
			
			if (deferFunc == null)
			{
				throw new ArgumentError("deferFunc");
			}
			
			errorType = errorType || Error;
			
			return new ClosureObservable(source.valueClass, function(obs:IObserver) : ICancelable
			{
				var subscription : ICancelable = null;
				
				subscription = source.subscribe(
					function(pl:Object) : void { obs.onNext(pl); },
					function() : void { obs.onCompleted(); },
					function(e : Error) : void
					{
						if (e is errorType)
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
		
		public function combineLatest(returnType : Class, right:IObservable, selector:Function):IObservable
		{
			var left : IObservable = this;
			
			return new ClosureObservable(returnType, function(observer : IObserver) : ICancelable 
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
					leftSubscription.innerSubscription = left.subscribe(
						function(v:Object) : void
						{
							leftValue = v;
							leftHasValue = true;
							checkValue();
						},
						function():void { leftComplete = true; checkComplete(); },
						observer.onError);
					
					rightSubscription.innerSubscription = right.subscribe(
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
		
		public function concat(sources:Array):IObservable
		{
			sources = [this].concat(sources);
			
			return Observable.concat(this.valueClass, sources);
		}
		
		public function contains(value : Object, comparer : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			comparer = (comparer == null)
				? defaultComparer
				: ComparerUtil.normalizeComparer(comparer);
			
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
				
				future.innerSubscription = source.subscribe(
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
				
				future.innerSubscription = source.materialize().subscribe(
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
								scheduler.schedule(function():void { pl.accept(observer); })
							);
						}
						else
						{
							var delayMs : Number = dtValue - now;
							
							scheduledActions.push( 
								scheduler.schedule(function():void { pl.accept(observer); }, delayMs)
							);
						}
					}
					);
					
				return scheduledActions;
			});
		}
		
		public function dematerialize(type : Class):IObservable
		{
			var source : IObservable = this;
			
			if (source.valueClass != Notification)
			{
				throw new ArgumentError("dematerialize can only be called on IObservable of " +
					"Notification, which is returned by materialize");
			}
			
			return new ClosureObservable(type, function(observer : IObserver):ICancelable
			{
				var dec : IObserver = new ClosureObserver(
					function(pl : Notification) : void
					{
						switch(pl.kind)
						{
							case NotificationKind.ON_NEXT:
								observer.onNext(pl.value);
								break;
							case NotificationKind.ON_COMPLETED:
								observer.onCompleted();
								break;
							case NotificationKind.ON_ERROR:
								observer.onError(pl.error);
								break;
						}
					});
					
				return source.subscribeWith(dec);
			});
		}
		
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
		
		public function forkJoin(resultType : Class, right : IObservable, selector : Function):IObservable
		{
			return this.combineLatest(resultType, right, selector).takeLast(1);
		}
		
		public function asObservable():IObservable
		{
			var source : IObservable = this;
			
			return Observable.defer(source.valueClass, function():IObservable
			{
				return source;
			});
		}
		
		public function distinctUntilChanged(comparer:Function = null):IObservable
		{
			var source : IObservable = this;
			
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			comparer = (comparer == null)
				? defaultComparer
				: ComparerUtil.normalizeComparer(comparer);
			
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
		
		public function let(func : Function) : IObservable
		{
			return IObservable(func(this));
		}
		
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
		
		public function merge(sources : IObservable, scheduler:IScheduler=null):IObservable
		{
			return Observable.merge(this.valueClass, sources.startWith([this], scheduler), scheduler);
		}
		
		public function ofType(type : Class) : IObservable
		{
			return this.where(function(x:Object):Boolean
			{
				return x is type;
			});
		}
		
		public function observeOn(scheduler:IScheduler):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.valueClass, function(observer : IObserver):ICancelable
			{
				var first : FutureCancelable = new FutureCancelable();
				var second : FutureCancelable = new FutureCancelable();
				
				first.innerSubscription = scheduler.schedule(function():void
				{
					second.innerSubscription = source.subscribeWith(observer);
				});
				
				return new CompositeCancelable([first, second]);
			});
		}
				
		public function onErrorResumeNext(second:IObservable, scheduler:IScheduler=null):IObservable
		{
			return Observable.onErrorResumeNext([this, second], scheduler);
		}
		
		public function prune(scheduler : IScheduler = null) : IConnectableObservable
		{
			return new ConnectableObservable(this, new AsyncSubject(this.valueClass, scheduler));
		}
		
		public function pruneAndConnect(selector : Function, scheduler : IScheduler = null) : IObservable
		{
			return new ClosureObservable(this.valueClass, function(obs:IObserver):ICancelable
			{
				var connectable : IConnectableObservable = prune(scheduler);
				
				var subscription : CompositeCancelable = new CompositeCancelable([]);
				 
				subscription.add( IConnectableObservable(selector(connectable)).subscribeWith(obs) );
				subscription.add( connectable.connect() );
				
				return subscription;
			});
		}
		
		public function publish() : IConnectableObservable
		{
			return new ConnectableObservable(this, new Subject(this.valueClass));
		}
		
		public function publishAndConnect(selector : Function) : IObservable
		{
			return new ClosureObservable(this.valueClass, function(obs:IObserver):ICancelable
			{
				var connectable : IConnectableObservable = publish();
				
				var subscription : CompositeCancelable = new CompositeCancelable([]);
				 
				subscription.add( IConnectableObservable(selector(connectable)).subscribeWith(obs) );
				subscription.add( connectable.connect() );
				
				return subscription;
			});
		}
		
		public function removeTimeInterval(type : Class) : IObservable
		{
			if (this.valueClass != TimeInterval)
			{
				throw new IllegalOperationError("Cannot remove timeInterval from observable that is of type " +
					getQualifiedClassName(this.valueClass));
			}
			
			return this.select(type, function(ts:TimeInterval):Object
			{
				return ts.value;
			});
		}
		
		public function removeTimestamp(type : Class) : IObservable
		{
			if (this.valueClass != TimeStamped)
			{
				throw new IllegalOperationError("Cannot remove timestamp from observable that is of type " +
					getQualifiedClassName(this.valueClass));
			}
			
			return this.select(type, function(ts:TimeStamped):Object
			{
				return ts.value;
			});
		}
		
		public function replay(bufferSize : uint = 0, window : uint = 0, 
			scheduler : IScheduler = null) : IConnectableObservable
		{
			return new ConnectableObservable(this, 
				new ReplaySubject(this.valueClass, bufferSize, window, scheduler));
		}
		
		public function replayAndConnect(selector : Function, bufferSize : uint = 0, 
			window : uint = 0, scheduler : IScheduler = null) : IObservable
		{
			return new ClosureObservable(this.valueClass, function(obs:IObserver):ICancelable
			{
				var connectable : IConnectableObservable = replay(bufferSize, window, scheduler);
				
				var subscription : CompositeCancelable = new CompositeCancelable([]);
				 
				subscription.add( IConnectableObservable(selector(connectable)).subscribeWith(obs) );
				subscription.add( connectable.connect() );
				
				return subscription;
			});
		}
		
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
								subscription.innerSubscription = source.subscribeWith(recursiveObserver);
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
					subscription.innerSubscription = source.subscribeWith(recursiveObserver);
				});
				
				return subscription;
			});
		}
		
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
								subscription.innerSubscription = source.subscribeWith(recursiveObserver);
							});
						}
						else
						{
							observer.onError(err);
						}
					});
				
				Scheduler.immediate.schedule(function():void
				{
					subscription.innerSubscription = source.subscribeWith(recursiveObserver);
				});
				
				return subscription;
			});
		}
		
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
		
		public function scan(accumulator : Function, outputType : Class = null, initialValue : Object = null) : IObservable
		{
			var useInitialValue : Boolean = (outputType != null);
			
			if (!useInitialValue)
			{
				outputType = this.valueClass; 
			}
			
			var source : IObservable = this;
			
			return Observable.defer(outputType, function():IObservable
			{
				var skipFirst : Boolean = true;
				var accumulatedValue : Object = null;
				
				if (useInitialValue)
				{
					skipFirst = false;
					accumulatedValue = initialValue;
				}
				
				return source.select(outputType, function(value:Object):Object
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
			
			return new ClosureObservable(outputType, function(obs:IObserver):ICancelable
			{
				var aggregate : Object = null;
				
				return 
			});
		}
		
		public function select(result : Class, selector:Function):IObservable
		{
			return selectInternal(result, selector);
		}
		
		private function selectInternal(type : Class, selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(type, function (observer : IObserver) : ICancelable
			{
				var countSoFar : uint = 0;
				
				var subscription : FutureCancelable = new FutureCancelable();
				
				subscription.innerSubscription = source.subscribe(
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
		
		public function selectMany(type : Class, selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return Observable.merge(type, this.select(IObservable, selector)); 
		}
		
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
				
				futureSubscription.innerSubscription = source.subscribe(
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
		
		public function startWith(values : Array, scheduler : IScheduler = null) : IObservable
		{
			return Observable
				.fromArray(this.valueClass, values, scheduler)
				.concat([this]);
		}

		public function sum():IObservable
		{
			return aggregate(function(x:Number, y:Number):Number
			{
				return x+y;
			}, valueClass, 0).catchError(Observable.returnValue(valueClass, 0));
		}
		
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
				
				Scheduler.immediate.schedule(function():void
				{
					subscription.innerSubscription = source.subscribeWith(decoratorObserver);
				});
				
				return subscription;
			});
		}
		
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
				
				futureSubscription.innerSubscription = source.subscribe(
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
				
				otherSubscription.innerSubscription = other.subscribe(
					function (value : Object) : void { observer.onCompleted(); },
					observer.onCompleted,
					observer.onError
					);
					
				primarySubscription.innerSubscription = source.subscribeWith(observer);
					
				
				return composite;
			});
		}
		
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
				
				timeout.innerSubscription = scheduler.schedule(function():void
				{
					subscription.cancel();
					subscription = other.subscribeWith(observer);
				}, timeoutMs);
				
				subscription.innerSubscription = source.subscribe(
					function (value : Object) : void
					{
						timeout.innerSubscription = scheduler.schedule(timeout, timeoutMs);
						
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
		
		public function timestamp(scheduler:IScheduler=null):IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			return selectInternal(TimeStamped, function(value : Object) : TimeStamped
			{
				return new TimeStamped(value, scheduler.now.time);
			});
		}
		
		include "operators/include.as"
		
		public function zip(resultType : Class, rightSource:IObservable, selector:Function):IObservable
		{
			// TODO: Could this be replaced with a single-plan join?
			
			var source : IObservable = this;
			
			return new ClosureObservable(resultType, function (observer : IObserver) : ICancelable
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
					
				leftSubscription.innerSubscription = source.subscribeWith(leftObserver);
				rightSubscription.innerSubscription = rightSource.subscribeWith(rightObserver);
				
				return new ClosureCancelable(function():void
				{
					new CompositeCancelable([leftSubscription, rightSubscription]).cancel();
				});
			});
		}		
	}
}