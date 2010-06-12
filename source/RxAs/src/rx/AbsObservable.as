package rx
{
	import flash.errors.IllegalOperationError;
	import flash.utils.getQualifiedClassName;
	
	import rx.impl.*;
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
		
		public function get type() : Class
		{
			return Object;
		}
		
		public function subscribe(observer : IObserver) : ICancelable
		{
			// Abstract methods not supported by AS3
			throw new IllegalOperationError("subscribe() must be overriden");
		}
		
		public function subscribeFunc(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : ICancelable
		{
			var observer : IObserver = new ClosureObserver(onNext, onComplete, onError);
			
			return subscribe(observer);
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
			
			return new ClosureObservable(source.type, function(obs:IObserver):ICancelable
			{
				var total : Number = 0;
				var count : Number = 0;
				
				return source.subscribeFunc(
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
			}, type, 0);
		}
		
		public function any(predicate : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			predicate = predicate || function(o:Object):Boolean { return true; }
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				return source.subscribeFunc(
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
					function (error : Error) : void { observer.onError(error); }
					);
			});
		}
		
		public function all(predicate : Function) : IObservable
		{
			var source : IObservable = this;
			
			predicate = predicate || function(o:Object):Boolean { return true; }
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				return source.subscribeFunc(
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
					function (error : Error) : void { observer.onError(error); }
					);
			});
		}
		
		public function asynchronous():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function bufferWithCount(count:int, skip:int=0):IObservable
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

			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
					
				return source.subscribe(dec);
			});
		}
		
		public function bufferWithTime(timeMs:int, timeShiftMs:int=0, scheduler:IScheduler=null):IObservable
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
			
			scheduler = Observable.resolveScheduler(scheduler);

			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
					.subscribeFunc(intervalFunc);
				
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
						flushBuffer();
						observer.onError(error);
					});
					
				var subscription : ICancelable = 
					source.timestamp(scheduler).subscribe(dec);
				
				return new ClosureSubscription(function():void 
				{
					subscription.cancel();
					intervalSubscription.cancel();
				});
			});
		}
		
		public function cast(type : Class) : IObservable
		{
			return this.select(type, function(x:Object):Object
			{
				if (x != null)
				{
					var obj : Object = x as type;
					
					if (obj == null)
					{
						var fromType : String = getQualifiedClassName(x);
						var toType : String = getQualifiedClassName(type);
						
						throw new TypeError(
							"Error #1034: Type Coercion failed: cannot convert " +
							fromType + " to " + toType
						);
					}
				}
				
				return x;
			});
		}
		
		public function catchError(second : IObservable, scheduler : IScheduler = null) : IObservable
		{
			return Observable.catchErrors([this, second], scheduler);
		}
		
		public function catchErrorDefered(errorType : Class, deferFunc : Function) : IObservable
		{
			var source : IObservable = this;
			
			if (deferFunc == null)
			{
				throw new ArgumentError("deferFunc");
			}
			
			errorType = errorType || Error;
			
			return new ClosureObservable(source.type, function(obs:IObserver) : ICancelable
			{
				var subscription : ICancelable = null;
				
				subscription = source.subscribeFunc(
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
								subscription = catchObservable.subscribe(obs);
							} 
						}
						else
						{
							obs.onError(e);
						}
					});
				
				return new ClosureSubscription(function():void
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
				var leftSubscription : FutureSubscription = new FutureSubscription();
				var leftValue : Object = null;
				var leftComplete : Object = null;
				var leftHasValue : Object = null;
				
				var rightSubscription : FutureSubscription = new FutureSubscription();
				var rightValue : Object = null;
				var rightComplete : Object = null;
				var rightHasValue : Object = null;				
				
				var subscriptions : CompositeSubscription = new CompositeSubscription(
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
					leftSubscription.innerSubscription = left.subscribeFunc(
						function(v:Object) : void
						{
							leftValue = v;
							leftHasValue = true;
							checkValue();
						},
						function():void { leftComplete = true; checkComplete(); },
						observer.onError);
					
					rightSubscription.innerSubscription = right.subscribeFunc(
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
		
		public function concat(sources:Array, scheduler:IScheduler=null):IObservable
		{
			sources = [this].concat(sources);
			
			return Observable.concat(this.type, sources, scheduler);
		}
		
		public function contains(value : Object, comparer : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			comparer = (comparer == null)
				? defaultComparer
				: ComparerUtil.normalizeComaparer(comparer);
			
			return new ClosureObservable(Boolean, function(observer : IObserver) : ICancelable
			{
				return source.subscribeFunc(
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
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function delay(delayMs:int, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = scheduler || Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				var scheduledActions : Array = [];
				var nextScheduledAction : ICancelable = null;
				var completeScheduledAction : ICancelable = null;
				
				var subscription : ICancelable = source.subscribeFunc(
					function(pl : Object) : void
					{
						scheduledActions.push( 
							scheduler.schedule(function():void { scheduledActions.shift(); observer.onNext(pl); }, delayMs)
						);
					},
					function () : void
					{
						scheduledActions.push( 
							scheduler.schedule(function():void { scheduledActions.shift(); observer.onCompleted(); }, delayMs)
						);
					},
					function (error : Error) : void
					{
						while (scheduledActions.length > 0)
						{
							scheduledActions.shift().cancel();
						}
						
						observer.onError(error);
					}
					);
					
				return new ClosureSubscription(function():void
				{
					while (scheduledActions.length > 0)
					{
						scheduledActions.shift().cancel();
					}
				});
			});
		}
		
		public function delayUntil(dt:Date, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			var dtValue : Number = dt.time;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				scheduler = scheduler || Observable.resolveScheduler(scheduler);
				
				var isPastDate : Boolean = (scheduler.now.time >= dtValue);
				var scheduledActions : Array = [];
				
				var subscription : ICancelable = source.materialize().subscribeFunc(
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
							scheduledActions.push(
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
					
				return new ClosureSubscription(function():void
				{
					while(scheduledActions.length > 0)
					{
						scheduledActions.shift().cancel();
					}
					
					subscription.cancel();
				});
			});
		}
		
		public function dematerialize(type : Class):IObservable
		{
			var source : IObservable = this;
			
			if (source.type != Notification)
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
					
				return source.subscribe(dec);
			});
		}
		
		public function doAction(nextAction:Function, completeAction:Function = null, errorAction:Function = null):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
							if (completeAction == null && errorAction == null)
							{
								observer.onError(err);
							}
							else
							{
								throw err;
							}
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
					
				return source.subscribe(dec);
			});
		}
		
		public function finallyAction(action:Function):IObservable
		{
			if (action == null) throw new ArgumentError("finallyAction");
			
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				var subscription : ICancelable = source.subscribe(observer);
				
				return new ClosureSubscription(function():void
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
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						observer.onNext(pl);
						observer.onCompleted();
					},
					function () : void { observer.onError(new Error("The sequence contained no values")); },
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function firstOrDefault():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function forkJoin(resultType : Class, right : IObservable, selector : Function):IObservable
		{
			return this.zip(resultType, right, selector).take(1);
		}
		
		public function asObservable():IObservable
		{
			var source : IObservable = this;
			
			return Observable.defer(source.type, function():IObservable
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
				: ComparerUtil.normalizeComaparer(comparer);
			
			return new ClosureObservable(Boolean, function(observer : IObserver) : ICancelable
			{
				var lastValue : Object = null;
				var hasValue : Boolean = false;
				
				return source.subscribeFunc(
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
					
					function():void { observer.onCompleted(); },
					function(e : Error):void { observer.onError(e); }
				);
			});
		}
		
		public function join(plans:Array):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function last():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function lastOrDefault():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function latest():Array
		{
			throw new IllegalOperationError("Not implemented");
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
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void { observer.onNext(new OnNext(pl)); },
					function () : void { observer.onNext(new OnCompleted()); observer.onCompleted(); },
					function (error : Error) : void { observer.onNext(new OnError(error)); observer.onCompleted(); });
					
				return source.subscribe(dec);
			});
		}
		
		public function merge(sources : IObservable, scheduler:IScheduler=null):IObservable
		{
			return Observable.merge(this.type, sources.startWith([this], scheduler), scheduler);
		}
		
		public function mostRecent(initialValue:Object):IObservable
		{
			throw new IllegalOperationError("Not implemented");
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
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				var subscription : ICancelable = null;
				
				var scheduledAction : ICancelable = scheduler.schedule(function():void
				{
					subscription = source.subscribe(observer);
				});
				
				return new ClosureSubscription(function():void
				{
					if (subscription == null)
					{
						scheduledAction.cancel();
					}
					else
					{
						subscription.cancel();
					}
				});
			});
		}
				
		public function onErrorResumeNext(second:IObservable, scheduler:IScheduler=null):IObservable
		{
			return Observable.onErrorResumeNext([this, second], scheduler);
		}
		
		public function prune(scheduler : IScheduler = null) : IConnectableObservable
		{
			return new ConnectableObservable(this, new AsyncSubject(this.type, scheduler));
		}
		
		public function pruneAndConnect(selector : Function, scheduler : IScheduler = null) : IObservable
		{
			return new ClosureObservable(this.type, function(obs:IObserver):ICancelable
			{
				var connectable : IConnectableObservable = prune(scheduler);
				
				var subscription : CompositeSubscription = new CompositeSubscription([]);
				 
				subscription.add( IConnectableObservable(selector(connectable)).subscribe(obs) );
				subscription.add( connectable.connect() );
				
				return subscription;
			});
		}
		
		public function publish() : IConnectableObservable
		{
			return new ConnectableObservable(this, new Subject(this.type));
		}
		
		public function publishAndConnect(selector : Function) : IObservable
		{
			return new ClosureObservable(this.type, function(obs:IObserver):ICancelable
			{
				var connectable : IConnectableObservable = publish();
				
				var subscription : CompositeSubscription = new CompositeSubscription([]);
				 
				subscription.add( IConnectableObservable(selector(connectable)).subscribe(obs) );
				subscription.add( connectable.connect() );
				
				return subscription;
			});
		}
		
		public function removeTimeInterval(type : Class) : IObservable
		{
			if (this.type != TimeInterval)
			{
				throw new IllegalOperationError("Cannot remove timeInterval from observable that is of type " +
					getQualifiedClassName(this.type));
			}
			
			return this.select(type, function(ts:TimeInterval):Object
			{
				return ts.value;
			});
		}
		
		public function removeTimestamp(type : Class) : IObservable
		{
			if (this.type != TimeStamped)
			{
				throw new IllegalOperationError("Cannot remove timestamp from observable that is of type " +
					getQualifiedClassName(this.type));
			}
			
			return this.select(type, function(ts:TimeStamped):Object
			{
				return ts.value;
			});
		}
		
		public function replay(bufferSize : uint = 0, window : uint = 0, 
			scheduler : IScheduler = null) : IConnectableObservable
		{
			return new ConnectableObservable(this, new ReplaySubject(this.type, bufferSize, window, scheduler));
		}
		
		public function replayAndConnect(selector : Function, bufferSize : uint = 0, 
			window : uint = 0, scheduler : IScheduler = null) : IObservable
		{
			return new ClosureObservable(this.type, function(obs:IObserver):ICancelable
			{
				var connectable : IConnectableObservable = replay(bufferSize, window, scheduler);
				
				var subscription : CompositeSubscription = new CompositeSubscription([]);
				 
				subscription.add( IConnectableObservable(selector(connectable)).subscribe(obs) );
				subscription.add( connectable.connect() );
				
				return subscription;
			});
		}
		
		public function repeat(repeatCount:uint=0):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				var isInfinite : Boolean = (repeatCount == 0);
				var iterationsRemaining : uint = repeatCount - 1;
				
				var subscription : FutureSubscription = new FutureSubscription();				
				var recursiveObserver : IObserver = null;
				
				recursiveObserver = new ClosureObserver(
					function(pl:Object) : void { observer.onNext(pl); },
					function():void
					{
						if (isInfinite || iterationsRemaining-- > 0)
						{
							Scheduler.immediate.schedule(function():void
							{
								subscription.innerSubscription = source.subscribe(recursiveObserver);
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
					subscription.innerSubscription = source.subscribe(recursiveObserver);
				});
				
				return subscription;
			});
		}
		
		public function retry(retryCount:int = 0):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
			{
				var isInfinite : Boolean = (retryCount == 0);
				var iterationsRemaining : uint = retryCount - 1;
				
				var subscription : FutureSubscription = new FutureSubscription();				
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
								subscription.innerSubscription = source.subscribe(recursiveObserver);
							});
						}
						else
						{
							observer.onError(err);
						}
					});
				
				Scheduler.immediate.schedule(function():void
				{
					subscription.innerSubscription = source.subscribe(recursiveObserver);
				});
				
				return subscription;
			});
		}
		
		public function returnValue(value:Object):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function scan(accumulator : Function, outputType : Class = null, initialValue : Object = null) : IObservable
		{
			var useInitialValue : Boolean = (outputType != null);
			
			if (!useInitialValue)
			{
				outputType = this.type; 
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
				
				var subscription : ICancelable;
				
				var decoratorObserver : IObserver = new ClosureObserver(
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
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				subscription = source.subscribe(decoratorObserver);
				
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
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function singleOrDefault():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function(observer : IObserver):ICancelable
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
						observer.onNext(value);
						observer.onCompleted();
					},
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function skip(count:int):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
			{
				var skippedSoFar : uint = 0;
				
				var subscription : ICancelable;
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						if (++skippedSoFar > count)
						{
							observer.onNext(value);
						}
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				subscription = source.subscribe(decoratorObserver);
				
				return subscription;
			});
		}
		
		public function skipUntil(other:IObservable):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
			{
				var subscription : ICancelable;
				
				var pastSkip : Boolean = false;
				
				var primarySubscription : ICancelable;
				var otherSubscription : ICancelable;
				
				primarySubscription = source.subscribeFunc(
					function (value : Object) : void
					{
						if (pastSkip)
						{
							observer.onNext(value);
						}
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
					
				otherSubscription = other.subscribeFunc(
					function (value : Object) : void
					{
						pastSkip = true;
						if (otherSubscription != null)
						{
							otherSubscription.cancel();
						}
					},
					function () : void  { },
					function (error : Error) : void  { observer.onError(error); }
					);
				
				if (pastSkip)
				{
					otherSubscription.cancel();
					otherSubscription = null;
				}
				
				return new ClosureSubscription(function():void
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
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
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
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				return source.subscribe(decoratorObserver);
			});
		}
		
		public function startWith(values : Array, scheduler : IScheduler = null) : IObservable
		{
			return Observable
				.returnValues(this.type, values, scheduler)
				.concat([this], scheduler);
		}

		public function sum():IObservable
		{
			return aggregate(function(x:Number, y:Number):Number
			{
				return x+y;
			}, type, 0).catchError(Observable.returnValue(type, 0));
		}
		
		public function take(count:int, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			if (count == 0)
			{
				return Observable.empty(this.type, scheduler); 
			}
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
			{
				var countSoFar : uint = 0;
				
				var subscription : FutureSubscription = new FutureSubscription();
				
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
					subscription.innerSubscription = source.subscribe(decoratorObserver);
				});
				
				return subscription;
			});
		}
		
		public function takeUntil(other:IObservable):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
			{
				var subscription : ICancelable;
				
				var primarySubscription : ICancelable;
				var otherSubscription : ICancelable;
				
				primarySubscription = source.subscribeFunc(
					function (value : Object) : void
					{
						observer.onNext(value);
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
					
				otherSubscription = other.subscribeFunc(
					function (value : Object) : void { observer.onCompleted(); },
					function () : void  { observer.onCompleted(); },
					function (error : Error) : void  { observer.onError(error); }
					);
				
				return new ClosureSubscription(function():void
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
		
		public function takeWhile(predicate:Function):IObservable
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
						else
						{
							observer.onCompleted();
						}
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				return source.subscribe(decoratorObserver);
			});
		}
		
		public function throttle(dueTimeMs:int, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
			{
				var lastValueTimestamp : Number = 0;
				
				var subscription : ICancelable;
				
				var decoratorObserver : IObserver = new ClosureObserver(
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
				
				subscription = source.timestamp(scheduler).subscribe(decoratorObserver);
				
				return subscription;
			});
		}
		
		public function timeInterval(scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(TimeInterval, function (observer : IObserver) : ICancelable
			{
				var lastTimeMs : Number = -1;
				
				var decoratorObserver : IObserver = new ClosureObserver(
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
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				return source.subscribe(decoratorObserver);
			});
		}
		
		public function timeout(timeoutMs:int, other:IObservable=null, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			other = other || Observable.throwError(new TimeoutError("Sequence timed out"), this.type);
			
			scheduler = Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(source.type, function (observer : IObserver) : ICancelable
			{
				var subscription : FutureSubscription = new FutureSubscription();
				
				var timeout : Function = function():void
				{
					subscription.cancel();
					subscription = other.subscribe(observer);
				};
				
				var timeoutAction : ICancelable = scheduler.schedule(timeout, timeoutMs);
				
				subscription.innerSubscription = source.subscribeFunc(
					function (value : Object) : void
					{
						timeoutAction.cancel();
						timeoutAction = scheduler.schedule(timeout, timeoutMs);
						
						observer.onNext(value);
					},
					function () : void
					{
						timeoutAction.cancel();
						observer.onCompleted();
					},
					observer.onError
					);
				
				return new ClosureSubscription(function():void
				{
					timeoutAction.cancel();
					subscription.cancel();
				});
			});
		}
		
		public function timestamp(scheduler:IScheduler=null):IObservable
		{
			scheduler = Observable.resolveScheduler(scheduler);
			
			return selectInternal(TimeStamped, function(value : Object) : TimeStamped
			{
				return new TimeStamped(value, scheduler.now.time);
			});
		}
		
		public function toAsync(func:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		include "operators/include.as"
		
		public function zip(resultType : Class, rightSource:IObservable, selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(resultType, function (observer : IObserver) : ICancelable
			{
				var canceled : Boolean = false;
				
				var leftComplete : Boolean = false;
				var leftValues : Array = new Array();
				
				var rightComplete : Boolean = false;
				var rightValues : Array = new Array();
				
				var leftSubscription : FutureSubscription = new FutureSubscription(), 
					rightSubscription : FutureSubscription = new FutureSubscription();
				
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
					
				leftSubscription.innerSubscription = source.subscribe(leftObserver);
				rightSubscription.innerSubscription = rightSource.subscribe(rightObserver);
				
				return new ClosureSubscription(function():void
				{
					new CompositeSubscription([leftSubscription, rightSubscription]).cancel();
				});
			});
		}		
	}
}