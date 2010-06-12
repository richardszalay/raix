package rx
{
	import flash.display.LoaderInfo;
	import flash.errors.IllegalOperationError;
	import flash.events.*;
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncToken;
	
	import rx.flex.*;
	import rx.impl.*;
	import rx.scheduling.*;

	public class Observable
	{
		public function Observable()
		{
			throw new IllegalOperationError("This class is static and cannot be instantiated. Create an IObservable by using one of Observable's static methods");
		}
		
		public static function amb(sources : Array/*.<IObservable>*/) : IObservable
		{
			sources = new Array().concat(sources);
			
			return new ClosureObservable(int, function(observer : IObserver) : ICancelable
			{
				var subscription : CompositeSubscription = new CompositeSubscription([])
			
				for each(var source : IObservable in sources)
				{
					(function(obs:IObservable):void
					{
						var futureSubscription : FutureSubscription = new FutureSubscription();
						subscription.add(futureSubscription);
					
						futureSubscription.innerSubscription = obs.subscribeFunc(
							function(pl:Object) : void
							{
								var newSubscriptions : CompositeSubscription = 
									new CompositeSubscription(subscription.subscriptions);
									
								newSubscriptions.remove(futureSubscription);
								newSubscriptions.cancel();
								
								observer.onNext(pl);
							},
							function():void { observer.onCompleted(); },
							function(e:Error):void { observer.onError(e); }
							);
					})(source);
				}
				
				return subscription;
			});
		}
		
		public static function create(subscribeFunc : Function) : IObservable
		{
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var cancelFunc : Function = subscribeFunc(observer) as Function;
				
				return new ClosureSubscription(function():void
				{
					if (cancelFunc != null)
					{
						cancelFunc();
					}
				});
			});
		}
		
		public static function concat(type : Class, sources : Array, scheduler:IScheduler=null) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("");
			}
			
			sources = new Array().concat(sources);
			
			scheduler = scheduler || Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(type, function(observer : IObserver):ICancelable
			{
				var remainingSources : Array = [].concat(sources);
				var currentSource : IObservable = remainingSources.shift();
			
				var schedule : FutureSubscription = new FutureSubscription();
				var subscription : FutureSubscription = new FutureSubscription();
				
				var composite : CompositeSubscription = new CompositeSubscription([schedule, subscription]);
				
				
				var dec : IObserver = null;
				
				var onComplete : Function = function () : void
				{
					if (remainingSources.length > 0)
					{
						currentSource = IObservable(remainingSources.shift());
						
						schedule.innerSubscription = scheduler.schedule(function():void
						{
							subscription.innerSubscription = currentSource.subscribe(dec);
						});
					}
					else
					{
						observer.onCompleted();
					}
				}
				
				dec = new ClosureObserver(observer.onNext, onComplete, observer.onError);

				schedule.innerSubscription = scheduler.schedule(function():void
				{
					subscription.innerSubscription = currentSource.subscribe(dec);
				});
				
				return composite;
			});
		}
		
		public static function defer(type : Class, observableFactory:Function):IObservable
		{
			if (observableFactory == null)
			{
				throw new ArgumentError("observableFactory cannot be null");
			}
			
			return new ClosureObservable(type, function(observer : IObserver):ICancelable
			{
				var observable : IObservable = observableFactory();
				
				if (observable.type != type)
				{
					throw new ArgumentError("Deffered observable type must match type given to defer"); 
				}
				
				return observable.subscribe(observer);
			});
		}
		
		public static function generate(type : Class, initialState : Object, predicate : Function, resultMap : Function, 
			iterate : Function, scheduler : IScheduler = null) : IObservable
		{
			scheduler = resolveScheduler(scheduler);
			
			return new ClosureObservable(type, function(observer : IObserver) : ICancelable
			{
				var currentState : Object = initialState;
				var firstIteration : Boolean = true;
				
				var recursiveAction : Function = function(reschedule : Function):void
				{
					var useValue : Boolean = false;
					var outputValue : Object = resultMap;
					
					try
					{
						if (firstIteration)
						{
							firstIteration = !firstIteration;
						}
						else
						{
							currentState = iterate(currentState);
						}
						
						useValue = predicate(currentState);
						
						if (useValue)
						{
							outputValue = resultMap(currentState);
						}
					}
					catch(err : Error)
					{
						observer.onError(err);
						return;
					}
					
					if (useValue)
					{
						observer.onNext(outputValue);
						reschedule();
					}
					else
					{
						observer.onCompleted();
					}
				};
				
				var scheduledAction : ICancelable = 
					Scheduler.scheduleRecursive(scheduler, recursiveAction);
				
				return new ClosureSubscription(function():void
				{
					scheduledAction.cancel();
				});
			});
		}
		
		public static function interval(intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			return timer(intervalMs, intervalMs, scheduler);
		}
		
		public static function timer(delayMs : uint, intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			scheduler = Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(int, function(observer : IObserver) : ICancelable
			{
				var intervalIndex : uint = 0;
				
				var scheduledAction : FutureSubscription = new FutureSubscription();
				
				scheduledAction.innerSubscription = scheduler.schedule(function():void
					{
						observer.onNext(++intervalIndex);
						
						scheduledAction.innerSubscription = Scheduler.scheduleRecursive(scheduler,
							function(recurse : Function):void
							{
								observer.onNext(++intervalIndex);
								
								recurse();
							}, intervalMs);
					}, delayMs);
				
				return scheduledAction;
			});
		}
		
		public static function join(type : Class, plans : Array) : IObservable
		{
			return new ClosureObservable(type, function(observer : IObserver) : ICancelable
			{
				var activePlans : Array = new Array().concat(plans);
				var sources : Array = new Array();
				var queues : Dictionary = new Dictionary();
				var completed : Dictionary = new Dictionary();
				
				for each(var plan : Plan in activePlans)
				{
					var index : int = 0;
					
					for each(var source : IObservable in plan.sources)
					{
						if (plan.sources.indexOf(source, (index++) + 1) != -1)
						{
							observer.onError(new ArgumentError("Sources must be unique within a plan"));
							return ClosureSubscription.empty();
						}
						
						if (queues[source] == undefined)
						{
							sources.push(source);
							queues[source] = new Array();
							completed[source] = false;
						}
					}
				}
				
				var matchPlan : Function = function():void
				{
					var match : Plan = null;
					
					for each(var plan : Plan in activePlans)
					{
						var args : Array = new Array();
						
						for each(var source : IObservable in plan.sources)
						{
							if (queues[source].length > 0)
							{
								args.push(queues[source][0]);
							}
							else
							{
								break;
							}
						}
						
						if (args.length == plan.sources.length)
						{
							for each(var source : IObservable in plan.sources)
							{
								queues[source].shift();
								
								if (completed[source] && queues[source].length == 0)
								{
									delete queues[source];
									delete completed[source];
									sources.splice(sources.indexOf(source), 1);
								}
							}
							
							var value : Object = null;
							
							try
							{
								value = plan.selector.apply(NaN, args);
							}
							catch(err : Error)
							{
								observer.onError(err);
								return;
							}
							
							observer.onNext(value);
							
							checkComplete();
							
							break;
						}
					}
				};
				
				var checkComplete : Function = function():void
				{
					var tempPlans : Array = new Array().concat(activePlans);
					
					for each(var plan : Plan in tempPlans)
					{
						for each(var source : IObservable in plan.sources)
						{
							if (!queues[source] || (completed[source] && queues[source].length == 0))
							{
								activePlans.splice(activePlans.indexOf(plan), 1);								
								break;
							}
						}
					}
					
					if (sources.length == 0 || activePlans.length == 0)
					{
						observer.onCompleted();
					}
				};
					
				var subscriptions : CompositeSubscription = new CompositeSubscription([]);
				
				var tempSources : Array = sources.concat([]);
					
				for each(var source : IObservable in tempSources)
				{
					(function(source:IObservable):void
					{
						var safetyObserver : SafetyObserver = new SafetyObserver(new ClosureObserver(
							function(v:Object):void
							{
								queues[source].push(v);
								matchPlan();
							},
							function():void
							{
								if (queues[source].length == 0)
								{
									delete queues[source];
									delete completed[source];
									sources.splice(sources.indexOf(source), 1);
									
									checkComplete();
								}
								else
								{
									completed[source] = true;
								}
							},
							observer.onError));
							
						var subscription : ICancelable = source.subscribe(safetyObserver);
						
						subscriptions.add(subscription);
						
						safetyObserver.setSubscription(subscription);
						
					})(source);
				}
				
				return subscriptions;
			});
		}
		
		public static function fromEvent(eventDispatcher:IEventDispatcher, type:String, eventType : Class = null, useCapture:Boolean=false, priority:int=0):IObservable
		{
			eventType = eventType || Event;
			
			if (eventDispatcher == null)
			{
				throw new ArgumentError("eventDispatcher cannot be null");
			}
			
			return new ClosureObservable(eventType, function(observer : IObserver, scheduler : IScheduler = null) : ICancelable
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var listener : Function = function(event : Event) : void
				{
					scheduler.schedule(function():void
					{
						observer.onNext(event);
					});
				};
				
				scheduler.schedule(function():void
				{
					eventDispatcher.addEventListener(type, listener, useCapture, priority);
				});
				
				return new ClosureSubscription(function():void
				{
					eventDispatcher.removeEventListener(type, listener, useCapture);
				});
			});
		}
		
		public static function empty(observableType : Class = null, scheduler : IScheduler = null) : IObservable
		{
			observableType = observableType || Object;
			scheduler = scheduler || ImmediateScheduler.instance;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ICancelable
			{
				return new ScheduledActionSubscription(
					scheduler.schedule(obs.onCompleted)
				);
			});
		}
		
		public static function onErrorResumeNext(sources:Array, scheduler:IScheduler=null):IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].type, function(obs:IObserver) : ICancelable
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : ICancelable = null;
				var futureSubscription : FutureSubscription = new FutureSubscription();
				
				var scheduledAction : ICancelable = null;
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
					
					if (subscription != null)
					{
						subscription.cancel();
					}
					
					subscription = currentSource.subscribeFunc(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onCompleted();
							}
						},
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
					
					futureSubscription.innerSubscription = subscription;
				};
				
				scheduledAction = scheduler.schedule(moveNextFunc);
				
				return new ClosureSubscription(function():void
				{
					if (scheduledAction != null)
					{
						scheduledAction.cancel();
					}
					
					if (futureSubscription != null)
					{
						futureSubscription.cancel();
					}
				});
			});
		}
		
		/**
		 * Returns an IObservable that never completes
		 */		
		public static function never(observableType : Class = null) : IObservable
		{
			observableType = observableType || Object;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ICancelable
			{
				return new ClosureSubscription(function():void{});
			});
		}
		
		public static function uncaughtErrors(loaderInfo : LoaderInfo = null) : IObservable
		{
			loaderInfo = loaderInfo || LoaderInfo.getLoaderInfoByDefinition(Observable);
			
			var uncaughtErrorsSupported : Boolean = 
				loaderInfo.hasOwnProperty("uncaughtErrorEvents");
			
			if (uncaughtErrorsSupported)
			{
				return fromEvent(
					IEventDispatcher(loaderInfo["uncaughtErrorEvents"]),
					"uncaughtError"
					);
			}
			else
			{
				return never();
			}
		}
		
		public static function range(start : int, count : uint, scheduler : IScheduler = null) : IObservable
		{
			scheduler = Observable.resolveScheduler(scheduler);
			
			if (count < 0)
			{
				throw new RangeError("count must be > 0");
			}
			
			var end : int = start + count;
			
			return generate(int, start,
				function(i:int):Boolean { return i<end; },
				function(i:int):int { return i; },
				function(i:int):int { return i+1; },
				scheduler
				);
			
			/*
			return new ClosureObservable(int, function(obs:IObserver) : ISubscription
			{
				var end : int = start + count;
				
				var scheduledActions : Array = new Array();
				
				var scheduledAction : ICancelable = null;
				
				var i : int = start;
				
				var rescursiveAction : Function = null;
				
				rescursiveAction = function():void
				{
					obs.onNext(i);
					
					i++;
					
					if (i < end)
					{
						scheduledAction = scheduler.schedule(rescursiveAction);
					}
					else
					{
						obs.onCompleted();
					}
				};
				
				scheduledAction = scheduler.schedule(rescursiveAction);

				return new ClosureSubscription(function():void
				{
					scheduledAction.cancel();
				});
			});*/
		}
		
		public static function throwError(error : Error, observableType : Class = null) : IObservable
		{
			if (error == null)
			{
				throw new ArgumentError("error cannot be null");
			}
			
			observableType = observableType || Object;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ICancelable
			{
				obs.onError(error);
				
				return new ClosureSubscription(function():void{});
			});
		}
		
		public static function returnValues(type : Class, values : Array, scheduler : IScheduler = null) : IObservable
		{
			scheduler = resolveScheduler(scheduler);
			
			return new ClosureObservable(type, function(obs:IObserver) : ICancelable
			{
				var valueScheduledAction : ICancelable = null;
				
				for each(var value : Object in values) 
				{
					(function(value:Object) : void
					{
						valueScheduledAction = 
							scheduler.schedule(function():void { obs.onNext(value); });
					})(value);
				}
				
				var completeScheduledAction : ICancelable =
					scheduler.schedule(function():void { obs.onCompleted(); });
				
				return new ClosureSubscription(function():void
				{
					valueScheduledAction.cancel();
					completeScheduledAction.cancel();
				});
			});
		}
		
		public static function returnValue(type : Class, value : Object, scheduler : IScheduler = null) : IObservable
		{
			return returnValues(type, [value], scheduler); 
		}
		
		public static function catchErrors(sources : Array, scheduler : IScheduler = null) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].type, function(obs:IObserver) : ICancelable
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : ICancelable = null;
				var scheduledAction : ICancelable = null;
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
						
					subscription = currentSource.subscribeFunc(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void { obs.onCompleted(); },
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
				};
				
				scheduledAction = scheduler.schedule(moveNextFunc);
				
				return new ClosureSubscription(function():void
				{
					if (scheduledAction != null)
					{
						scheduledAction.cancel();
					}
					
					if (subscription != null)
					{
						subscription.cancel();
					}
				});
			});
		}
		
		public static function resolveScheduler(scheduler : IScheduler) : IScheduler
		{
			return scheduler || Scheduler.defaultScheduler;
		}		
		
		public static function merge(type : Class, source : IObservable, scheduler : IScheduler = null) : IObservable
		{
			if (source.type != IObservable)
			{
				throw new ArgumentError("merge can only merge an IObservable of IObservables");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			return new ClosureObservable(type, function(obs:IObserver) : ICancelable
			{
				var subscription : CompositeSubscription = new CompositeSubscription([]);
				
				var sourceComplete : Boolean = false;
				
				subscription.add(source.subscribeFunc(
					function(innerSource:IObservable) : void
					{
						if (innerSource == null)
						{
							throw new IllegalOperationError("Cannot merge null IObservable");
						}
						
						var innerSubscription : FutureSubscription = new FutureSubscription();
						subscription.add(innerSubscription);
						
						innerSubscription.innerSubscription = innerSource.subscribeFunc(
							function(pl:Object) : void
							{
								obs.onNext(pl);
							},
							function() : void
							{
								innerSubscription.cancel();
								subscription.remove(innerSubscription);
								
								if (sourceComplete && subscription.count == 1)
								{
									obs.onCompleted();
								}
							},
							function(e:Error) : void { obs.onError(e); }
						);
					},
					function() : void
					{
						sourceComplete = true;
						
						if (subscription.count == 1)
						{
							obs.onCompleted();
						}
					},
					function(e:Error) : void { obs.onError(e); }
					));
				
				return subscription;
			});
		}
		
		public static function call(action : Function, type : Class = null, scheduler : IScheduler = null) : IObservable
		{
			scheduler = resolveScheduler(scheduler);
			
			type = type || Unit;
			
			return new ClosureObservable(type, function(obs:IObserver) : ICancelable
			{
				var scheduledAction : ICancelable = scheduler.schedule(function():void
				{
					try
					{
						var ret : Object = action();
					}
					catch(err : Error)
					{
						obs.onError(err);
						return;
					}
					
					obs.onNext(ret);
					obs.onCompleted();
				});
				
				return new ScheduledActionSubscription(scheduledAction);
			});
		}
		
		CONFIG::FLEX
		{
			public static function fromAsyncPattern(returnType : Class, asyncMethod : Function, 
				args : Array) : IObservable 
			{
				return defer(returnType, function():IObservable
				{
					// TODO: Catch/rethrow type coercion error here?
					var token : AsyncToken = asyncMethod.apply(NaN, args);
					
					var responder : IObservableResponder = responder(returnType);
					token.addResponder(responder);
					
					return responder;
				});
			}
			
			public static function responder(type : Class) : IObservableResponder
			{
				return new ObservableResponder(type);
			}
		}
	}
}