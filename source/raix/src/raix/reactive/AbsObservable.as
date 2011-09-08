package raix.reactive
{
	import flash.errors.IllegalOperationError;
	import flash.utils.getQualifiedClassName;
	
	import raix.reactive.impl.*;
	import raix.reactive.scheduling.*;
	import raix.reactive.subjects.AsyncSubject;
	import raix.reactive.subjects.ConnectableObservable;
	import raix.reactive.subjects.IConnectableObservable;
	import raix.reactive.subjects.ReplaySubject;
	
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
		public function reduce(accumulator : Function, initialValue : Object = null, useInitialValue : Boolean = false) : IObservable
		{
			return scan(accumulator, initialValue, useInitialValue).last();
		}
		
		/**
		 * @inheritDoc
		 */
		public function aggregate(accumulator : Function, initialValue : Object = null, useInitialValue : Boolean = false) : IObservable
		{
			return reduce(accumulator, initialValue, useInitialValue);
		}
		
		/**
		 * @inheritDoc
		 */
		public function average(valueSelector : Function = null):IObservable
		{
			var source : IObservable = (valueSelector == null)
				? this
				: this.map(valueSelector);
			
			return new ClosureObservable(function(obs:IObserver):ICancelable
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
			
			return reduce(function(x:Number, y:Number):Number
			{
				return x+y;
			}, 0);
		}
		
		/**
		 * @inheritDoc
		 */
		public function any(predicate : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			predicate = predicate || function(o:Object):Boolean { return true; }
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			return windowWithCount(count, skip)
				.mapMany(function(v:IObservable):IObservable
				{
					return v.toArray();
				})
				.filter(function(v:Array):Boolean { return v.length > 0; });
		}
		
		/**
		 * @inheritDoc
		 */
		public function windowWithCount(count:uint, skip:uint=0):IObservable
		{
			if (count == 0)
			{
				throw new ArgumentError("count must be > 0");
			}
			
			// skip == count and skip == 0 are functionally equivalent
			if (skip == 0)
			{
				skip = count;
			}
			
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var activeWindows : Array = new Array();
				var valueCount : int = 0;
				
				var createWindow : Function = function():void
				{
					var window : Subject = new Subject();
					activeWindows.push(window);
					observer.onNext(window);
				};
				
				createWindow();
				
				return source.subscribe(
						function(v:Object) : void
						{
							for each(var subject : Subject in activeWindows)
							{
								subject.onNext(v);
							}
							
							var unusedValues : int = (valueCount - count + 1);
							
							if (unusedValues >= 0 && (unusedValues % skip) == 0)
							{
								activeWindows.splice(0, 1)[0].onCompleted();
							}
							
							valueCount++;
							
							if ((valueCount % skip) == 0)
							{
								createWindow();
							}
						},
						function():void
						{
							for (var i:int=0; i<activeWindows.length; i++)
							{
								activeWindows[i].onCompleted();
							}
							
							activeWindows = [];
							
							observer.onCompleted();
							
						}, function(e:Error):void
						{
							for (var i:int=0; i<activeWindows.length; i++)
							{
								activeWindows[i].onError(e);
							}
							
							activeWindows = [];
							
							observer.onError(e);
						});
			});
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function bufferWithTime(timeMs:uint, timeShiftMs:uint=0, scheduler:IScheduler=null):IObservable
		{
			return windowWithTime(timeMs, timeShiftMs, scheduler)
				.mapMany(function(v:IObservable):IObservable
				{
					return v.toArray();
				});
		}
		
		/**
		 * @inheritDoc
		 */
		public function windowWithTime(timeMs:uint, timeShiftMs:uint=0, scheduler:IScheduler=null):IObservable
		{
			if (timeMs == 0)
			{
				throw new ArgumentError("timeMs must be > 0");
			}
			
			// skip == count and skip == 0 are functionally equivalent
			if (timeShiftMs == 0)
			{
				timeShiftMs = timeMs;
			}
			
			scheduler = scheduler || Scheduler.synchronous;
			
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var activeWindows : Array = new Array();
				
				var nextSpanTime : Number = timeMs;
				var nextShiftTime : Number = timeShiftMs;
				var totalTime : Number = 0;
				
				var subscriptions : CompositeCancelable = new CompositeCancelable([]);
				
				var checkWindowSchedule : MutableCancelable = new MutableCancelable();
				subscriptions.add(checkWindowSchedule);
				
				var checkWindow : Function;
				 
				checkWindow = function():void
				{
					var isSpan : Boolean = false,
						isShift : Boolean = false;
						
					if (nextSpanTime == nextShiftTime)
					{
						isSpan = true;
						isShift = true;
					}
					else if (nextSpanTime < nextShiftTime)
					{
						isSpan = true;
					}
					else
					{
						isShift = true;
					}
					
					var scheduleMs : Number = isSpan ? nextSpanTime : nextShiftTime;
					var dueTime : Number = scheduleMs - totalTime;
					totalTime = scheduleMs;
					
					if (isSpan)
					{
						nextSpanTime += timeShiftMs;
					}
					if (isShift)
					{
						nextShiftTime += timeShiftMs;
					}
					
					checkWindowSchedule.cancelable = scheduler.schedule(function():void
					{
						if (isShift)
						{
							var window : Subject = new Subject();
							activeWindows.push(window);
							observer.onNext(window);
						}
						if (isSpan)
						{
							activeWindows.splice(0, 1)[0].onCompleted();
						}
						
						checkWindow();
						
					}, dueTime);
				};
				
				subscriptions.add(scheduler.schedule(function():void
				{
					var window : Subject = new Subject();
					activeWindows.push(window);
					observer.onNext(window);
					
					checkWindow();
					
					var sourceSubscription : MutableCancelable = new MutableCancelable();
					
					subscriptions.add(sourceSubscription);
					
					sourceSubscription.cancelable = source.subscribe(
						function(v:Object) : void
						{
							for each(var subject : Subject in activeWindows)
							{
								subject.onNext(v);
							}
						},
						function():void
						{
							for each(var subject : Subject in activeWindows)
							{
								subject.onCompleted();
							}
							
							observer.onCompleted();
							
						}, function(e:Error):void
						{
							for each(var subject : Subject in activeWindows)
							{
								subject.onError(e);
							}
							
							observer.onError(e);
						});
				}));
					
				return subscriptions;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function bufferWithTimeOrCount(timeMs:uint, count:uint, scheduler:IScheduler=null):IObservable
		{
			return windowWithTimeOrCount(timeMs, count, scheduler)
				.mapMany(function(v:IObservable):IObservable
				{
					return v.toArray();
				});
		}
		
		/**
		 * @inheritDoc
		 */
		public function windowWithTimeOrCount(timeMs:uint, count:uint, scheduler:IScheduler=null):IObservable
		{
			if (timeMs == 0)
			{
				throw new ArgumentError("timeMs must be > 0");
			}
			
			if (count == 0)
			{
				throw new ArgumentError("count must be > 0");
			}
			
			scheduler ||= Scheduler.synchronous;

			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var currentTimeout : MutableCancelable = new MutableCancelable();
				var sourceSubscription : MutableCancelable = new MutableCancelable();
				
				var subscriptions : CompositeCancelable = 
					new CompositeCancelable([currentTimeout, sourceSubscription]);
				
				var window : Subject = null;
				var createNewWindow : Function = null;
				var windowItemCount : uint = 0;
				
				createNewWindow = function():void
				{
					if (window != null)
					{
						window.onCompleted();
					}
					
					windowItemCount = 0;
					window = new Subject();
					observer.onNext(window);
					
					currentTimeout.cancelable = scheduler.schedule(createNewWindow, timeMs);
				};
				
				createNewWindow();
				
				sourceSubscription.cancelable = source.subscribe(
						function(v:Object) : void
						{
							window.onNext(v);
							windowItemCount++;
							
							if (windowItemCount == count)
							{
								createNewWindow();
							}
						},
						function():void
						{
							window.onCompleted();
							observer.onCompleted();
							
						}, function(e:Error):void
						{
							window.onError(e);
							observer.onError(e);
						});
						
					return subscriptions;
				});
		}
		
		/**
		 * @inheritDoc
		 */
		public function cast(valueClass : Class) : IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
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
			
			return new ClosureObservable(function(obs:IObserver) : ICancelable
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
		public function chain(functions : Array) : IObservable
		{
			var source : IObservable = this;
			
			for each(var selector : Function in functions)
			{
				source = source.mapMany(selector);
			}
			
			return source;
		}
		
		/**
		 * @inheritDoc
		 */
		public function combineLatest(right:IObservable, selector:Function):IObservable
		{
			var left : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable 
			{
				var leftSubscription : MutableCancelable = new MutableCancelable();
				var leftValue : Object = null;
				var leftComplete : Object = null;
				var leftHasValue : Object = null;
				
				var rightSubscription : MutableCancelable = new MutableCancelable();
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
					leftSubscription.cancelable = left.subscribe(
						function(v:Object) : void
						{
							leftValue = v;
							leftHasValue = true;
							checkValue();
						},
						function():void { leftComplete = true; checkComplete(); },
						observer.onError);
					
					rightSubscription.cancelable = right.subscribe(
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
		public function concat(source:IObservable):IObservable
		{
			return Observable.concat([this, source]);
		}
		
		/**
		 * @inheritDoc
		 */		
		public function concatMany(selector : Function) : IObservable
		{
			return Observable.concat(this.map(function(v:Object):IObservable
			{
				return Observable.defer(function():IObservable
				{
					return selector(v) as IObservable;
				});
			}));
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
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var scheduledActions : CompositeCancelable = new CompositeCancelable([]);
				var nextScheduledAction : ICancelable = null;
				var completeScheduledAction : ICancelable = null;
				
				var future : MutableCancelable = new MutableCancelable();
				
				var composite : ICancelable = new CompositeCancelable([scheduledActions, future]);
				
				future.cancelable = source.subscribe(
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				scheduler = scheduler || scheduler || Scheduler.synchronous;
				
				var isPastDate : Boolean = (scheduler.now.time >= dtValue);
				var scheduledActions : CompositeCancelable = new CompositeCancelable([]);
				
				var future : MutableCancelable = new MutableCancelable();
				scheduledActions.add(future);				
				
				future.cancelable = source.materialize().subscribe(
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
		public function dematerialize():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				return source.subscribe(
					function(pl : Notification) : void { pl.acceptWith(observer); }
				);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function peek(nextAction:Function, completeAction:Function = null, errorAction:Function = null):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
		public function peekWith(observer : IObserver):IObservable
		{
			return peek(observer.onNext, observer.onCompleted, observer.onError);
		}
		
		/**
		 * @inheritDoc
		 */
		public function expand(selector : Function) : IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var sources : Subject = new Subject();

				var subscription : MutableCancelable = new MutableCancelable();
				
				var activeCount : uint = 1;
				
				var sourceWithPeek : IObservable = source.peek(null, function():void
				{
					activeCount--;
					
					if (activeCount == 0)
					{
						sources.onCompleted();
					}
				});
				
				subscription.cancelable = Observable.merge(sources.startWith(Observable.value(sourceWithPeek)))
					.subscribe(function(v:Object):void
					{
						observer.onNext(v);
						
						var inner : IObservable;
						
						try
						{
							inner = selector(v);
						}
						catch(err : Error)
						{
							sources.onError(err);
							return;
						}
						
						activeCount++;
						
						sources.onNext(inner.peek(null, function():void
						{
							activeCount--;
					
							if (activeCount == 0)
							{
								sources.onCompleted();
							}
						}));
					}, observer.onCompleted, observer.onError);
					
				return subscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function finallyAction(action:Function):IObservable
		{
			if (action == null) throw new ArgumentError("finallyAction");
			
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
		public function forkJoin(right : IObservable, selector : Function):IObservable
		{
			return this.combineLatest(right, selector).takeLast(1);
		}
		
		/**
		 * @inheritDoc
		 */
		public function join(right : IObservable, 
			leftWindowSelector : Function, rightWindowSelector : Function, 
			joinSelector : Function) : IObservable
		{
			var source : IObservable = this;
			
			return Observable.createWithCancelable(function(observer:IObserver) : ICancelable
			{
				return source.groupJoin(right, leftWindowSelector, rightWindowSelector, function(leftValue:Object, joinedRightValues:IObservable) : Object
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
			joinSelector : Function) : IObservable
		{
			var source : IObservable = this;
			
			return Observable.createWithCancelable(function(observer:IObserver) : ICancelable
			{
				var leftSubscription : MutableCancelable = new MutableCancelable();
				var rightSubscription : MutableCancelable = new MutableCancelable();
				
				var windowSubscriptions : CompositeCancelable = new CompositeCancelable();
				
				var activeLeftSubjects : Array = new Array();
				// Need to track key/values seperately because Dictionary does not 
				// guarantee enumeration order
				var activeRightKeys : Array = new Array();
				var activeRightValues : Array = new Array();
				var rightID : int = int.MIN_VALUE;
				
				var subscription : CompositeCancelable = new CompositeCancelable([
					leftSubscription, rightSubscription, windowSubscriptions]);
				
				var leftComplete : Boolean = false;
				var rightComplete : Boolean = false;
				
				var onError : Function = function(error : Error) : void
				{
					for each(var leftWindow : Subject in activeLeftSubjects)
					{
						leftWindow.onError(error)						
					}
					
					observer.onError(error);
				};
				
				leftSubscription.cancelable = source
					.subscribe(function(leftValue : Object) : void
					{
						var leftWindow : IObservable;
						var rightValuesSubject : Subject = new Subject();
						var returnValue : Object;
						
						try
						{
							leftWindow = IObservable(leftWindowSelector(leftValue));
							
							returnValue = joinSelector(leftValue, rightValuesSubject.asObservable());
						}
						catch(error : Error)
						{
							onError(error);
							return;
						}
						
						observer.onNext(returnValue);
						
						for each(var activeRightValue : Object in activeRightValues)
						{
							rightValuesSubject.onNext(activeRightValue);
						}
						
						var leftWindowSubscription : MutableCancelable = new MutableCancelable();
						windowSubscriptions.add(leftWindowSubscription);
						
						activeLeftSubjects.push(rightValuesSubject);
							
						leftWindowSubscription.cancelable = leftWindow
							.take(1)
							.finallyAction(function():void
							{
								activeLeftSubjects.splice(activeLeftSubjects.indexOf(rightValuesSubject), 1);
								windowSubscriptions.remove(leftWindowSubscription);
							})
							.subscribe(null, function():void
							{
								rightValuesSubject.onCompleted();
								
								if (leftComplete && activeLeftSubjects.length == 1)
								{
									observer.onCompleted();
								}
								
							}, onError);
					},
					function():void
					{
						leftComplete = true;
						
						if (rightComplete || activeLeftSubjects.length == 0)
						{
							observer.onCompleted();
						}
					},
					onError);
					
				rightSubscription.cancelable = right.subscribe(
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
							onError(error);
							return;
						}
						
						activeRightKeys.push(activeRightValueID);;
						activeRightValues.push(rightValue);
						
						var rightWindowSubscription : MutableCancelable = new MutableCancelable();
						windowSubscriptions.add(rightWindowSubscription);
						
						rightWindowSubscription.cancelable = rightWindow
							.take(1)
							.finallyAction(function():void
							{
								var index : int = activeRightKeys.indexOf(activeRightValueID);
								activeRightKeys.splice(index, 1);
								activeRightValues.splice(index, 1);

								windowSubscriptions.remove(rightWindowSubscription);
							})
							.subscribe(null, function():void
							{
								if (rightComplete && activeRightValues.length == 1)
								{
									for each(var activeSubject : Subject in activeLeftSubjects)
									{
										activeSubject.onCompleted();
									}
									
									observer.onCompleted();
								}
							}, onError);
					},
					function() : void
					{
						rightComplete = true;
						
						if ((leftComplete && activeLeftSubjects.length == 0) || activeRightValues.length == 0)
						{
							for each(var activeSubject : Subject in activeLeftSubjects)
							{
								activeSubject.onCompleted();
							}
							
							observer.onCompleted();
						}
					},
					onError);
					
				return subscription;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function groupBy(keySelector : Function, elementSelector : Function = null, 
			keyComparer : Function = null) : IObservable
		{
			var never : IObservable = Observable.never();
			
			return groupByUntil(keySelector, 
				function(groupedObservable : IGroupedObservable) : IObservable
				{
					return never;
				},
				elementSelector, keyComparer);
		}
		
		/**
		 * @inheritDoc
		 */
		public function groupByUntil(keySelector : Function, durationSelector : Function, elementSelector : Function = null,  keyComparer : Function = null) : IObservable
		{
			var source : IObservable = this;
			
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			keyComparer = (keyComparer == null)
				? defaultComparer
				: normalizeComparer(keyComparer);
				
			elementSelector = (elementSelector == null)
				? function(x:Object) : Object { return x; }
				: elementSelector;
			
			return Observable.createWithCancelable(function(observer : IObserver) : ICancelable
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
				
				var sourceSubscription : MutableCancelable = new MutableCancelable();
				var durationSubscriptions : CompositeCancelable = new CompositeCancelable();
				
				sourceSubscription.cancelable = source.subscribe(
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
							groupSubject = new Subject();
							
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
							
							var durationSubscription : MutableCancelable = new MutableCancelable();

						    durationSubscriptions.add(durationSubscription);
						    
						    observer.onNext(group);
						    groupSubject.onNext(element);
							
							durationSubscription.cancelable = groupDuration
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
			
			return Observable.defer(function():IObservable
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
			
			return filter(function(v:Object):Boolean { return false; });
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
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
		
		public function log(message : String) : IObservable
		{
			return peek(
				function(v:Object):void { trace(message + " onNext(" + v + ")"); },
				function():void { trace(message + " onCompleted"); },
				function(e:Error):void { trace(message + " onError(" + e.toString() + ")"); }
			);
		}
		
		/**
		 * @inheritDoc
		 */
		public function materialize():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
		public function merge(source : IObservable):IObservable
		{
			return Observable.merge([this, source]);
		}
		
		/**
		 * @inheritDoc
		 */
		public function mergeMany(selector : Function, concurrent : int = 0) : IObservable
		{
			return Observable.merge(this.map(function(v:Object):IObservable
			{
				return Observable.defer(function():IObservable
				{
					return selector(v) as IObservable;
				});
			}), concurrent);
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var scheduledAction : MutableCancelable = new MutableCancelable();
				
				var subscription : ICancelable = source.materialize()
					.subscribe(function(n:Notification):void
					{
						scheduledAction.cancelable = scheduler.schedule(function():void
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var first : MutableCancelable = new MutableCancelable();
				var second : MutableCancelable = new MutableCancelable();
				
				first.cancelable = scheduler.schedule(function():void
				{
					second.cancelable = source.subscribeWith(observer);
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
			return multicast(new AsyncSubject(scheduler));
		}
		
		/**
		 * @inheritDoc
		 */
		public function pruneDefer(selector : Function, scheduler : IScheduler = null) : IObservable
		{
			return multicastDefer(
				function():ISubject { return new AsyncSubject(scheduler); },
				selector
			);
		}
		
		/**
		 * @inheritDoc
		 */
		public function publish() : IConnectableObservable
		{
			return multicast(new Subject());
		}
		
		/**
		 * @inheritDoc
		 */
		public function publishDefer(selector : Function) : IObservable
		{
			return multicastDefer(
				function():ISubject { return new Subject(); },
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
		public function multicastDefer(subjectSelector : Function, selector : Function) : IObservable
		{
			return new ClosureObservable(function(obs:IObserver):ICancelable
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
		public function removeTimeInterval() : IObservable
		{
			return this.map(function(ts:TimeInterval):Object
			{
				return ts.value;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeTimestamp() : IObservable
		{
			return this.map(function(ts:TimeStamped):Object
			{
				return ts.value;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function replay(bufferSize : uint = 0, windowMs : uint = 0, 
			scheduler : IScheduler = null) : IConnectableObservable
		{
			return multicast(new ReplaySubject(bufferSize, windowMs, scheduler));
		}
		
		/**
		 * @inheritDoc
		 */
		public function replayDefer(selector : Function, bufferSize : uint = 0, windowMs : uint = 0, 
			scheduler : IScheduler = null) : IObservable
		{
			return multicastDefer(
				function():ISubject { return new ReplaySubject(bufferSize, windowMs, scheduler); },
				selector
			);
		}
		
		/**
		 * @inheritDoc
		 */
		public function repeat(repeatCount:uint=0):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var isInfinite : Boolean = (repeatCount == 0);
				var iterationsRemaining : int = repeatCount - 1;
				
				var subscription : MutableCancelable = new MutableCancelable();				
				var recursiveObserver : IObserver = null;
				
				recursiveObserver = new ClosureObserver(
					function(pl:Object) : void { observer.onNext(pl); },
					function():void
					{
						if (isInfinite || iterationsRemaining-- > 0)
						{
							Scheduler.immediate.schedule(function():void
							{
								subscription.cancelable = source.subscribeWith(recursiveObserver);
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
					subscription.cancelable = source.subscribeWith(recursiveObserver);
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var isInfinite : Boolean = (retryCount == 0);
				var iterationsRemaining : int = retryCount - 1;
				
				var subscription : MutableCancelable = new MutableCancelable();				
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
								subscription.cancelable = source.subscribeWith(recursiveObserver);
							});
						}
						else
						{
							observer.onError(err);
						}
					});
				
				Scheduler.immediate.schedule(function():void
				{
					subscription.cancelable = source.subscribeWith(recursiveObserver);
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
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
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
		public function scan(accumulator : Function, initialValue : Object = null, useInitialValue : Boolean = false) : IObservable
		{
			var source : IObservable = this;
			
			return Observable.defer(function():IObservable
			{
				var skipFirst : Boolean = true;
				var accumulatedValue : Object = null;
				
				if (useInitialValue)
				{
					skipFirst = false;
					accumulatedValue = initialValue;
				}
				
				return source.map(function(value:Object):Object
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
			
			return new ClosureObservable(function(obs:IObserver):ICancelable
			{
				var aggregate : Object = null;
				
				return 
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function map(selector:Function):IObservable
		{
			return mapInternal(selector);
		}
		
		/**
		 * @inheritDoc
		 */
		[Deprecated(replacement="map")]
		public function select(selector:Function):IObservable
		{
			return map(selector);
		}
		
		private function mapInternal(selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var subscription : MutableCancelable = new MutableCancelable();
				
				subscription.cancelable = source.subscribe(
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
		public function selectMany(selector:Function):IObservable
		{
			return mapMany(selector);
		}
		
		/**
		 * @inheritDoc
		 */
		public function mapMany(selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return Observable.merge(this.map(selector)); 
		}
		
		/**
		 * @inheritDoc
		 */		
		public function sequenceEqual(other : IObservable, valueComparer : Function = null) : IObservable
		{
			var defaultComparer : Function = function(a:Object, b:Object) : Boolean { return a == b; }
			
			valueComparer = (valueComparer == null)
				? defaultComparer
				: normalizeComparer(valueComparer);
				
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var connectableSource : IConnectableObservable = source.publish();
				var connectableOther : IConnectableObservable = other.publish();
				
				var zipComplete : Boolean = false;
				
				connectableSource
					.zip(connectableOther, function(l:Object,r:Object) : Boolean
					{
						return valueComparer(l,r);
					})
					.all(function(v:Boolean):Boolean { return v; })
					.subscribe(function(valid : Boolean) : void
					{
						if (!valid)
						{
							observer.onNext(false);
							observer.onCompleted();
						}
					},
					function():void
					{
						zipComplete = true;
					});
					
				Observable.merge([
						connectableSource, connectableOther
					])
					.subscribe(function(v:Object):void
					{
						if (zipComplete)
						{
							observer.onNext(false);
							observer.onCompleted();
						}
					}, function():void
					{
						observer.onNext(true);
						observer.onCompleted();
					}, observer.onError);
					
				return new CompositeCancelable([
					connectableSource.connect(),
					connectableOther.connect()
				]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function single():IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
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
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
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
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var buffer : Array = new Array();
				
				var futureSubscription : MutableCancelable = new MutableCancelable();
				
				futureSubscription.cancelable = source.subscribe(
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
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
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
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
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
		public function startWith(value : *) : IObservable
		{
			return toObservable(value)
				.concat(this);
		}
		
		/**
		 * @inheritDoc
		 */
		public function switchMany(selector : Function) : IObservable
		{
			var source : IObservable = this.map(selector);
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var parentCancelable : MutableCancelable = new MutableCancelable();
				var parentCompleted : Boolean = false;
				
				var childCancelable : MutableCancelable = new MutableCancelable();
				var childCompleted : Boolean = false;
				
				parentCancelable.cancelable = source.subscribe(
					function(child : IObservable) : void
					{
						childCancelable.cancelable = child.subscribe(
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
			return reduce(function(x:Number, y:Number):Number
			{
				return x+y;
			}, 0).catchError(Observable.value(0));
		}
		
		/**
		 * @inheritDoc
		 */
		public function take(count:uint):IObservable
		{
			var source : IObservable = this;
			
			if (count == 0)
			{
				return Observable.empty(); 
			}
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var countSoFar : uint = 0;
				
				var subscription : MutableCancelable = new MutableCancelable();
				
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
				
				subscription.cancelable = source.subscribeWith(decoratorObserver);
				
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
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var buffer : Array = new Array();
				
				var futureSubscription : MutableCancelable = new MutableCancelable();
				
				futureSubscription.cancelable = source.subscribe(
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
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var subscription : ICancelable;
				
				var primarySubscription : MutableCancelable = new MutableCancelable();
				var otherSubscription : MutableCancelable = new MutableCancelable();
				
				var composite : ICancelable = new CompositeCancelable([
					primarySubscription, otherSubscription
				]);
				
				otherSubscription.cancelable = other.subscribe(
					function (value : Object) : void { observer.onCompleted(); },
					observer.onCompleted,
					observer.onError
					);
					
				primarySubscription.cancelable = source.subscribeWith(observer);
					
				
				return composite;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function takeWhile(predicate:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
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
		public function then(thenFunction : Function) : Plan
		{
			return new Plan([this], thenFunction);
		}
		
		/**
		 * @inheritDoc
		 */
		public function throttle(dueTimeMs:uint, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = scheduler || Scheduler.asynchronous;
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var hasValue : Boolean = false;
				var lastValue : Object = null;
				var sourceSubscription : MutableCancelable = new MutableCancelable();
				var currentTimeout : MutableCancelable = new MutableCancelable();
				
				var throttleTimeout : Function = function():void
				{
					hasValue = false;
					observer.onNext(lastValue);
				};
				
				sourceSubscription.cancelable = source.subscribe(
					function (value : Object) : void
					{
						lastValue = value;
						hasValue = true;
						
						currentTimeout.cancelable = 
							scheduler.schedule(throttleTimeout, dueTimeMs);
					},
					function() : void
					{
						if (hasValue)
						{
							observer.onNext(lastValue);
							observer.onCompleted();
						}
					},
					observer.onError);
					
				return new CompositeCancelable(
					[sourceSubscription, currentTimeout]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function timeInterval(scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
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
			
			other = other || Observable.error(new TimeoutError("Sequence timed out"));
			
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var timeout : MutableCancelable = new MutableCancelable();
				var subscription : MutableCancelable = new MutableCancelable();
				
				var composite : ICancelable = new CompositeCancelable([timeout, subscription]);
				
				timeout.cancelable = scheduler.schedule(function():void
				{
					subscription.cancel();
					subscription = other.subscribeWith(observer);
				}, timeoutMs);
				
				subscription.cancelable = source.subscribe(
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
			
			return mapInternal(function(value : Object) : TimeStamped
			{
				return new TimeStamped(value, scheduler.now.time);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function toArray():IObservable
		{
			var source : IObservable = this;
			
			return Observable.createWithCancelable(function(observer : IObserver):ICancelable
			{
				var buffer : Array = new Array();
				
				return source.finallyAction(function():void
					{
						buffer = [];
					})
					.subscribe(
					function(v:Object):void
					{
						buffer.push(v);
					},
					function():void
					{
						observer.onNext(buffer);
						observer.onCompleted();
					},
					observer.onError);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function filter(predicate:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
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
		public function window(windowClosingSelector : Function) : IObservable
		{
			var source : IObservable = this;
			
			return Observable.createWithCancelable(function(observer : IObserver):ICancelable
			{
				var windowOpenings : Subject = new Subject();
				
				var multiWindowSubscription : MutableCancelable = new MutableCancelable();
				var activeWindowSubscription : MutableCancelable = new MutableCancelable();
				
				multiWindowSubscription.cancelable = multiWindow(windowOpenings.startWith([null]), 
					function(u:Unit):IObservable
					{
						var windowValues : AsyncSubject = new AsyncSubject();
						
						var closing : IObservable = IObservable(windowClosingSelector());
						
						activeWindowSubscription.cancelable = closing
							.take(1)
							.subscribe(null, function():void
							{
								windowValues.onCompleted();
								windowOpenings.onNext(null);
							},
							windowValues.onError);
						
						return windowValues;
					})
					.subscribeWith(observer);
				
				return new CompositeCancelable([multiWindowSubscription, activeWindowSubscription]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function multiWindow(windowOpenings : IObservable, windowClosingSelector : Function) : IObservable
		{
			var source : IObservable = this;
			
			return windowOpenings.groupJoin(this, 
				windowClosingSelector,
				function(x:Object) : IObservable { return Observable.empty(); },
				function(w:Object, values : IObservable) : IObservable
				{
					return values;
				});
		}
		
		/**
		 * @inheritDoc
		 */
		public function zip(rightSource:IObservable, selector:Function):IObservable
		{
			// TODO: Could this be replaced with a single-plan join?
			
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver) : ICancelable
			{
				var canceled : Boolean = false;
				
				var leftComplete : Boolean = false;
				var leftValues : Array = new Array();
				
				var rightComplete : Boolean = false;
				var rightValues : Array = new Array();
				
				var leftSubscription : MutableCancelable = new MutableCancelable(), 
					rightSubscription : MutableCancelable = new MutableCancelable();
				
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
							if (rightComplete)
							{
								observer.onCompleted();
							}
							else
							{
								leftValues.push(value);
							}
						}
					},
					function():void
					{
						leftComplete = true; 
						if (rightComplete || leftValues.length == 0) { observer.onCompleted(); }
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
							if (leftComplete)
							{
								observer.onCompleted();
							}
							else
							{
								rightValues.push(value);
							}
						}
					},
					function():void
					{
						rightComplete = true; 
						if (leftComplete || rightValues.length == 0) { observer.onCompleted(); }
					},
					observer.onError
					);
					
				leftSubscription.cancelable = source.subscribeWith(leftObserver);
				rightSubscription.cancelable = rightSource.subscribeWith(rightObserver);
				
				return new CompositeCancelable([leftSubscription, rightSubscription]);
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