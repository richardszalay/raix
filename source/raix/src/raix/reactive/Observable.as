package raix.reactive
{
	import flash.display.LoaderInfo;
	import flash.errors.IOError;
	import flash.errors.IllegalOperationError;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	
	import raix.reactive.flex.*;
	import raix.reactive.impl.*;
	import raix.reactive.scheduling.*;
	import raix.reactive.subjects.AsyncSubject;
	import raix.reactive.subjects.ReplaySubject;

	/**
	 * Provides static methods that create observable sequences
	 */
	public class Observable
	{
		private static var _unhandledErrorsSubject : Subject = new Subject();
		
		public function Observable()
		{
			throw new IllegalOperationError("This class is static and cannot be instantiated. Create an IObservable by using one of Observable's static methods");
		}
		
		/**
		 * Takes multiple source sequences and returns values from the first sequence to emit a value  
		 * @param sources The sources that will be subscribed to
		 * @return An observable sequence of the same valueClass as the first sequence in sources
		 */		
		public static function amb(sources : Array/*.<IObservable>*/) : IObservable
		{
			sources = sources.slice();
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var subscription : CompositeCancelable = new CompositeCancelable([])
			
				for each(var source : IObservable in sources)
				{
					(function(obs:IObservable):void
					{
						var futureSubscription : MutableCancelable = new MutableCancelable();
						subscription.add(futureSubscription);
					
						futureSubscription.cancelable = obs.subscribe(
							function(pl:Object) : void
							{
								var newSubscriptions : CompositeCancelable = 
									new CompositeCancelable(subscription.cancelables);
									
								newSubscriptions.remove(futureSubscription);
								newSubscriptions.cancel();
								
								observer.onNext(pl);
							},
							observer.onCompleted,
							observer.onError
							);
					})(source);
				}
				
				return subscription;
			});
		}
		
		/**
		 * Defers selection of the sequence to use by using a function that returns a key into a dictionary of sequences 
		 * @param keySelector The function that, at the moment of subscription, will return the key into dictionary
		 * @param dictionary The dictionary of sequences
		 * @return An observable sequence of valueClass
		 */		
		public static function lookup(keySelector : Function, dictionary : Dictionary) : IObservable
		{
			if (dictionary == null) throw new ArgumentError("dictionary cannot be null");
			if (keySelector == null) throw new ArgumentError("keySelector cannot be null");
			
			return defer(function():IObservable
			{
				var key : Object = null;
				
				try
				{
					key = keySelector();
				}
				catch(err : Error)
				{
					return Observable.error(err);
				}
				
				var val : Object = dictionary[key];
				
				if (val == undefined)
				{
					return Observable.empty();
				}
				
				var sequence : IObservable = val as IObservable;
				
				if (sequence == null)
				{
					var error : Error = new IllegalOperationError("lookup dictionary value for " + (key||"null") + 
						" was not an IObservable");
						
					return Observable.error(error);
				}
				
				return sequence;
			});
		}
		
		/**
		 * Creates a custom observable sequence  
		 * @param subscribeFunc The function that will be executed when a subscriber subscribes, the return value of which is a function to be run when the sequence is terminated
		 * @return An observable sequence of valueClass
		 */
		public static function create(subscribeFunc : Function) : IObservable
		{
			return createWithCancelable(function(observer : IObserver):ICancelable
			{
				var cancelFunc : Function = subscribeFunc(observer) as Function;
				
				if (cancelFunc == null)
				{
					throw new ArgumentError("Expected a Function to be returned from subscribeFunc");
				}
				
				return Cancelable.create(cancelFunc);
			});
		}
		
		/**
		 * Creates a custom observable sequence that uses cancelable resources  
		 * @param subscribeFunc The function that will be executed when a subscriber subscribes, the return value of which is an ICancelable to be canceled when the sequence is terminated
		 * @return An observable sequence of valueClass
		 */
		public static function createWithCancelable(subscribeFunc : Function) : IObservable
		{
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var cancelable : MutableCancelable = new MutableCancelable(); 
				
				try
				{
					cancelable.cancelable = subscribeFunc(observer) as ICancelable;
				}
				catch(error : Error)
				{
					observer.onError(error);
					return Cancelable.empty;
				}
				
				return cancelable;
			});
		}
		
		/**
		 * Concatonates multiple sequences by running each sequence as the previous one finishes 
		 * @param sources Anything that can be converted to an IObservable of IObservables using toObservable
		 * @return An observable sequence of valueClass
		 */		
		public static function concat(sources : *) : IObservable
		{
			return merge(sources, 1);
		}
		
		/**
		 * Defers selection of a sequence until the sequence is subscribed to  
		 * @param observableFactory The function that will be executed when a new subscription occurs, the returned sequence will be used for the subscriber.
		 * @return An observable sequence of valueClass
		 */		
		public static function defer(observableFactory:Function):IObservable
		{
			if (observableFactory == null)
			{
				throw new ArgumentError("observableFactory cannot be null");
			}
			
			return new ClosureObservable(function(observer : IObserver):ICancelable
			{
				var observable : IObservable = observableFactory();
				
				return observable.subscribeWith(observer);
			});
		}
		
		/**
		 * Creates a custom observable sequence that is controlled by methods supplied as arguments 
		 * @param initialState The initial state value to use (of class valueClass)
		 * @param predicate The predicate to determine whether the sequence has completed
		 * @param iterate The function executed between iterations
		 * @param resultMap The function that maps the current state to an output value
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of valueClass
		 */		
		public static function generate(initialState : Object, predicate : Function, iterate : Function, 
			resultMap : Function, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
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
				
				return Scheduler.scheduleRecursive(scheduler, recursiveAction);
			});
		}
		
		/**
		 * Defers selection of one of two sequences until the sequence is subscribed to
		 * @param predicate The function to execute when a subscription occurs to determine which sequence to subscribe to
		 * @param ifTrue The sequence to subscribe to if predicate returns true
		 * @param ifFalse The sequence to subscribe to if predicate returns false
		 * @return An observable sequence of valueClass
		 */
		public static function ifElse(predicate : Function, ifTrue : IObservable, ifFalse : IObservable) : IObservable
		{
			return defer(function():IObservable
			{
				try
				{
					return (predicate())
						? ifTrue
						: ifFalse;
				}
				catch(err : Error)
				{
					return Observable.error(err);
				}
				
				// Compiler bug workaround
				return null;
			});
		}
		
		/**
		 * Creates an unending observable sequence of integers that are incremented at a regular interval 
		 * @param intervalMs The interval, in milliseconds, to wait in between values
		 * @param scheduler The scheduler used for timing
		 * @return An observable sequence of int
		 */
		public static function interval(intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			return timer(intervalMs, intervalMs, scheduler);
		}
		
		/**
		 * Creates an unending observable sequence of integers that begin after a delay and are incremented at a regular interval 
		 * @param delayMs The interval, in milliseconds, to wait before the first value
		 * @param intervalMs The interval, in milliseconds, to wait in between subsequent values
		 * @param scheduler The scheduler used for timing
		 * @return An observable sequence of int
		 */
		public static function timer(delayMs : uint, intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var intervalIndex : uint = 0;
				
				var scheduledAction : MutableCancelable = new MutableCancelable();
				
				scheduledAction.cancelable = scheduler.schedule(function():void
					{
						observer.onNext(intervalIndex++);
						
						scheduledAction.cancelable = Scheduler.scheduleRecursive(scheduler,
							function(recurse : Function):void
							{
								observer.onNext(intervalIndex++);
								
								recurse();
							}, intervalMs);
					}, delayMs);
				
				return scheduledAction;
			});
		}
		
		/**
		 * Matches multiple plans (source sequence combinations) in the order they are specified 
		 * @param plans The array of rx.Plan objects creates using 'and' and 'then'
		 * @return An observable sequence of valueClass
		 */		
		public static function when(plans : Array) : IObservable
		{
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var activePlans : Array = new Array().concat(plans);
				var sources : Array = new Array();
				var queues : Dictionary = new Dictionary();
				var completed : Dictionary = new Dictionary();
				
				var source : IObservable = null;
				
				for each(var plan : Plan in activePlans)
				{
					var index : int = 0;
					
					for each(source in plan.sources)
					{
						if (plan.sources.indexOf(source, (index++) + 1) != -1)
						{
							observer.onError(new ArgumentError("Sources must be unique within a plan"));
							return ClosureCancelable.empty();
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
						
						for each(source in plan.sources)
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
							for each(source in plan.sources)
							{
								queues[source].shift();
								
								if (completed[source] && queues[source].length == 0)
								{
									delete queues[source];
									delete completed[source];
									sources.splice(sources.indexOf(source), 1);
								}
							}
							
							var val : Object = null;
							
							try
							{
								val = plan.selector.apply(NaN, args);
							}
							catch(err : Error)
							{
								observer.onError(err);
								return;
							}
							
							observer.onNext(val);
							
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
					
				var subscriptions : CompositeCancelable = new CompositeCancelable([]);
				
				var tempSources : Array = sources.concat([]);
					
				for each(source in tempSources)
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
							
						var subscription : ICancelable = source.subscribeWith(safetyObserver);
						
						subscriptions.add(subscription);
						
						safetyObserver.setSubscription(subscription);
						
					})(source);
				}
				
				return subscriptions;
			});
		}
		
		/**
		 * Subscribes to multiple source sequence and emits the last values of each after all have completed 
		 * @param sources The sequences to subscribe to
		 * @return An observable sequence of Array
		 */		
		public static function forkJoin(sources : Array) : IObservable
		{
			if (sources.length < 2)
			{
				throw new ArgumentError("At least two sources must be passed to forkJoin"); 
			}
			
			sources = new Array().concat(sources);
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var hasValue : Array = new Array(sources.length);
				var isComplete : Array = new Array(sources.length);
				var values : Array = new Array();
				
				var subscriptions : CompositeCancelable = new CompositeCancelable([]);
				
				var booleanPredicate : Function = function(v:Boolean, i:int, a:Array) : Boolean { return v; };
				
				for (var i:int =0;i<sources.length; i++)
				{
					(function(i:int):void
					{
						var source : IObservable = sources[i];
						
						subscriptions.add(source.subscribe(
							function(v:Object):void
							{
								values[i] = v;
								
								if (!hasValue[i])
								{
									hasValue[i] = true;
								}
							},
							function():void
							{
								isComplete[i] = true;
								
								if (isComplete.every(booleanPredicate))
								{
									if (hasValue.every(booleanPredicate))
									{
										observer.onNext(values.concat([]));
									}
									
									observer.onCompleted();
								}
							},
							observer.onError));
						
					})(i);
				}
				
				return subscriptions;
			});
		}
		
		/**
		 * Creates a sequence of events from an IEventDispatcher 
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param eventType The valueClass of event dispatched by eventDispatcher. Event will be used if this argument is null.
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @return An observable sequence of eventType, or Event if eventType is null
		 */		
		public static function fromEvent(eventDispatcher:IEventDispatcher, eventType:String, useCapture:Boolean=false, priority:int=0):IObservable
		{
			if (eventDispatcher == null)
			{
				throw new ArgumentError("eventDispatcher cannot be null");
			}
			
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var listener : Function = function(event : Event) : void
				{
					observer.onNext(event);
				};
				
				eventDispatcher.addEventListener(eventType, listener, useCapture, priority);
				
				return new ClosureCancelable(function():void
				{
					eventDispatcher.removeEventListener(eventType, listener, useCapture);
				});
			});
		}
		
		/**
		 * Creates Combines events from multiple event valueClasss 
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param eventTypes An array event type names
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @return An observable sequence of commonValueClass, or Event if commonValueClass is null 
		 */
		public static function fromEvents(eventDispatcher:IEventDispatcher, eventTypes:Array, useCapture:Boolean=false, priority:int=0):IObservable
		{
			return Observable.fromArray(eventTypes)
					.mapMany(function(eventType : String) : IObservable
					{
						return fromEvent(eventDispatcher, eventType, useCapture, priority);
					});
		}
		
		/**
		 * Creates a sequence that emits an error when an event is received from an IEventDispatcher  
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param eventType The event type
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @param errorMap The function that maps an event to an Error. null can be used if the event will be ErrorEvent
		 * @return An observable sequence of valueClass, or Object if valueClass is null 
		 */
		public static function fromErrorEvent(eventDispatcher:IEventDispatcher, eventType:String, useCapture:Boolean=false, priority:int=0, errorMap : Function = null):IObservable
		{
			return mapErrorEvents(
				fromEvent(eventDispatcher, eventType, useCapture, priority),
				errorMap
			);
		}
		
		/**
		 * Creates a sequence that emits an error when one of several event valueClasss is received from an IEventDispatcher
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param eventTypes The event types that signify an error
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @param errorMap The function that maps an event to an Error. null can be used if the event will be ErrorEvent
		 * @return An observable sequence of 
		 */		
		public static function fromErrorEvents(eventDispatcher:IEventDispatcher, eventTypes:Array, useCapture:Boolean=false, priority:int=0, errorMap : Function = null):IObservable
		{
			return mapErrorEvents(
				fromEvents(eventDispatcher, eventTypes, useCapture, priority),
				errorMap
			);
		}
		
		private static function mapErrorEvents(source : IObservable, errorMap : Function = null) : IObservable
		{
			errorMap = errorMap || ErrorUtil.mapErrorEvent;
			
			return source
				.take(1)
				.mapMany(function(event : Event) : IObservable
				{
					var error : Error = null;
					
					try
					{
						error = errorMap(event) as Error;
						
						if (error == null)
						{
							error = new Error("errorMap must return an instance of Error");
						}
					}
					catch(err : Error)
					{
						error = err;
					}
					
					return Observable.error(error);
				});
		}
		
		/**
		 * Creates a sequence that immediately completes  
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of valueClass
		 */		
		public static function empty(scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || ImmediateScheduler.instance;
			
			return new ClosureObservable(function(obs:IObserver) : ICancelable
			{
				return scheduler.schedule(obs.onCompleted);
			});
		}
		
		/**
		 * Concatonates a list of sequence as each one errors or complete 
		 * @param sources The list of sequences to concatonate
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the valueClass of the value sequence in sources
		 */		
		public static function onErrorResumeNext(sources:Array, scheduler:IScheduler=null):IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = scheduler || Scheduler.synchronous;
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(function(obs:IObserver) : ICancelable
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : ICancelable = null;
				var futureSubscription : MutableCancelable = new MutableCancelable();
				
				var scheduledAction : ICancelable = null;
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
					
					if (subscription != null)
					{
						subscription.cancel();
					}
					
					subscription = currentSource.subscribe(
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
					
					futureSubscription.cancelable = subscription;
				};
				
				scheduledAction = scheduler.schedule(moveNextFunc);
				
				return new ClosureCancelable(function():void
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
		public static function never() : IObservable
		{
			return new ClosureObservable(function(obs:IObserver) : ICancelable
			{
				return new ClosureCancelable(function():void{});
			});
		}
		
		/*
		 * Creates a sequences that accesses uncaught errors if supported by the platform (Flash Player 10.1+)
		 * @param loaderInfo The LoaderInfo to catch uncaught errors from, or the LoaderInfo into which rx.Observable was loaded if the argument is null
		 * @return An observable sequence of errors 
		*/
		public static function uncaughtErrors(loaderInfo : LoaderInfo = null) : IObservable
		{
			return Observable.merge(Observable.fromArray(
				[_unhandledErrorsSubject, getNativeUncaughtErrors(loaderInfo)]));
		}
		
		private static function getNativeUncaughtErrors(loaderInfo : LoaderInfo) : IObservable
		{
			if (loaderInfo == null)
			{
				throw new ArgumentError("loaderInfo cannot be null. Try stage.loaderInfo");
			}
			
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
		
		/**
		 * Creates a sequence of consecutive integers  
		 * @param start The inclusive start value of the range
		 * @param count The number of values, including start, to emit
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of int
		 */		
		public static function range(start : int, count : uint, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			if (count < 0)
			{
				throw new RangeError("count must be > 0");
			}
			
			var end : int = start + count;
			
			return generate(start,
				function(i:int):Boolean { return i<end; },
				function(i:int):int { return i+1; },
				function(i:int):int { return i; },
				scheduler
				);
		}
		
		/**
		 * Creates a sequence that immediately throws an Error  
		 * @param error The error to raise when a new subscription occurs
		 * @param valueClass The Class of the returned sequence
		 * @return An observable sequence of valueClass
		 */		
		public static function error(err : Error) : IObservable
		{
			if (err == null)
			{
				throw new ArgumentError("error cannot be null");
			}
			
			return new ClosureObservable(function(obs:IObserver) : ICancelable
			{
				obs.onError(err);
				
				return new ClosureCancelable(function():void{});
			});
		}
		
		/**
		 * Creates a sequence consisting of the values in an Array 
		 * @param values The array of values to iterate through
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of elementClass
		 */
		public static function fromArray(values : Array, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			values = values.slice();
			
			return Observable.generate(0,
				function(i : int):Boolean { return i < values.length; },
				function(i : int):int { return i+1; },
				function(i : int):Object { return values[i]; },
				scheduler);
		}
		
		/**
		 * Repeats a value a specification number of times 
		 * @param value The value to repeat
		 * @param repeatCount The number of times to emit the value
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of valueClass
		 */
		public static function repeatValue(val : Object, repeatCount : uint = 0, scheduler : IScheduler = null) : IObservable
		{
			return Observable.value(val, scheduler)
				.repeat(repeatCount);
		}
		
		/**
		 * Create a sequence consisting of exactly one value 
		 * @param value The value to emit
		 * @param scheduler The scheduler to use to control flow
		 * @return An observable sequence of valueClass
		 */		
		public static function value(val : Object, scheduler : IScheduler = null) : IObservable
		{
			return fromArray([val], scheduler); 
		}
		
		/**
		 * Concatonates a list of sequences as each one errors. A successful sequence ends the concatonation.  
		 * @param sources The list of sequence to concatonate.
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence with the valueClass of the first sequence in sources
		 */		
		public static function catchErrors(sources : Array, scheduler : IScheduler = null) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = scheduler || Scheduler.synchronous;
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(function(obs:IObserver) : ICancelable
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : MutableCancelable = new MutableCancelable();
				var scheduledAction : MutableCancelable = new MutableCancelable();
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
						
					subscription.cancelable = currentSource.subscribe(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void { obs.onCompleted(); },
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction.cancelable = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
				};
				
				scheduledAction.cancelable = scheduler.schedule(moveNextFunc);
				
				return new CompositeCancelable([scheduledAction, subscription]);
			});
		}
		
		/**
		 * Emits the values from multiple sources in the order that they arrive 
		 * @param source Either an array of IObservable or an IObservable of IObservables
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of valueClass
		 * @see raix.reactive.toObservable
		 */		
		public static function merge(sources : *, concurrent : uint = 0) : IObservable
		{
			var source : IObservable = toObservable(sources);
			
			return new ClosureObservable(function(obs:IObserver) : ICancelable
			{
				var subscription : CompositeCancelable = new CompositeCancelable([]);
				
				var sourceComplete : Boolean = false;
				
				var outerSubscription : MutableCancelable = new MutableCancelable();
				subscription.add(outerSubscription);
				
				var innerSubscriptions : CompositeCancelable = new CompositeCancelable();
				subscription.add(innerSubscriptions);
				
				var queue : ReplaySubject = new ReplaySubject();
				
				var queuedSource : IObservable = (concurrent == 0)
					? source
					: source.zip(queue, function(l:IObservable,r:Object):IObservable { return l; });
				
				outerSubscription.cancelable = queuedSource.subscribe(
					function(innerSource:IObservable) : void
					{
						if (innerSource == null)
						{
							throw new IllegalOperationError("Cannot merge null IObservable");
						}
						
						var innerSubscription : MutableCancelable = new MutableCancelable();
						innerSubscriptions.add(innerSubscription);
						
						innerSubscription.cancelable = innerSource.subscribe(
							obs.onNext,
							function() : void
							{
								innerSubscription.cancel();
								innerSubscriptions.remove(innerSubscription);
								
								if (sourceComplete && innerSubscriptions.count == 0)
								{
									obs.onCompleted();
								}
								else
								{
									queue.onNext(null);
								}
							},
							obs.onError
						);
					},
					function() : void
					{
						sourceComplete = true;
						
						subscription.remove(outerSubscription);
						
						if (innerSubscriptions.count == 0)
						{
							obs.onCompleted();
						}
					},
					obs.onError
					);
					
				if (concurrent != 0)
				{
					for (var i:int=0;i<concurrent;i++)
					{
						queue.onNext(null);
					}
				}
				
				return subscription;
			});
		}
		
		/**
		 * Creates a sequence based on a call to a function  
		 * @param action The function to call
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of valueClass
		 */		
		public static function start(action : Function, scheduler : IScheduler = null) : IObservable
		{
			return toAsync(action, scheduler)();
		}
		
		/**
		 * Converts a function into an observable sequence  
		 * @param action The function to call
		 * @param scheduler The scheduler to use
		 * @return A function accepting the arguments of the original action, but that will 
		 * return an IObservable when called.
		 */		
		public static function toAsync(action : Function, scheduler : IScheduler = null) : Function
		{
			scheduler = scheduler || Scheduler.asynchronous;
			
			var hasReturnValue : Boolean = true;
			
			return function (... args) : IObservable
			{
				return new ClosureObservable(function(obs:IObserver) : ICancelable
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
						
						if (hasReturnValue)
						{
							obs.onNext(ret);
						}
						obs.onCompleted();
					});
					
					return scheduledAction;
				});
			};
		}
		
		private static var _loaderQueueSubscription : ICancelable;
		private static var _loaderQueue : ISubject;
		
		/**
		 * Creates an observable sequence that loads an object from a URLRequest 
		 * @param request The URLRequest to load
		 * @param dataFormat A value of flash.net.URLLoaderDataFormat
		 * @param loaderContext The optional LoaderContext to use
		 * @return An observable sequence of Object
		 */
		public static function urlLoader(request : URLRequest, dataFormat : String = "text", loaderContext : LoaderContext = null) : IObservable
		{		
			var firstRequest : Boolean = (_loaderQueue == null);
			
			// Wait for the consumer to subscribe
			return Observable.createWithCancelable(function(observer : IObserver) : ICancelable
			{
				var cancelSignal : AsyncSubject = new AsyncSubject();
				
				if (firstRequest)
				{
					_loaderQueue = new ReplaySubject();
					_loaderQueueSubscription = merge(_loaderQueue, _maxConcurrentLoaders).subscribe(null);
				}
				
				var loader : IObservable = urlLoaderInternal(request, dataFormat, loaderContext);
				
				_loaderQueue.onNext(Observable.defer(function():IObservable
				{
					return loader
						.log(request.url)
						.peekWith(observer)
						.catchError(Observable.empty())
						.takeUntil(cancelSignal);
				}));
				
				return Cancelable.create(function():void
				{
					cancelSignal.onCompleted();
				});
			});
		}
		
		private static var _maxConcurrentLoaders : int = 2;
		
		/**
		 * Gets the maximum number of urlLoaders that can execute concurrently. The value 
		 * defaults to 2 to prevent issues in some browers. 
		 */
		public static function get maxConcurrentLoaders() : uint
		{
			return _maxConcurrentLoaders;
		}
		
		/**
		 * Sets the maximum number of urlLoaders that can execute concurrently. Use 0 for 
		 * no limit.
		 */
		public static function set maxConcurrentLoaders(value : uint) : void
		{
			if (_loaderQueue != null)
			{
				throw new IllegalOperationError("Observable.maxConcurrentLoaders cannot be changed after Observable.urlLoader is called");
			}
			
			_maxConcurrentLoaders = value;
		}
		
		private static function urlLoaderInternal(request : URLRequest, dataFormat : String = "text", loaderContext : LoaderContext = null) : IObservable
		{
			return new ClosureObservable(function(observer : IObserver) : ICancelable
			{
				var loader : URLLoader = new URLLoader();
				var loading : Boolean = false;
				
				var cancelable : ICancelable = new CompositeCancelable([
					Observable.fromEvent(loader, Event.COMPLETE)
					.subscribe(function(completeEvent : Event) : void
					{
						loading = false;
						observer.onNext(loader.data);
						observer.onCompleted();
					}),
					Observable.fromErrorEvents(loader, 
						[IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR])
					.subscribe(null, null, function(e : Error) : void
					{
						loading = false;
						observer.onError(e);
					}),
					Cancelable.create(function():void
					{
						if (loading)
						{
							try
							{
								loader.close();
							}
							catch(e:IOError) {}
						}
					})
				]);
				
				try
				{
					loading = true;
					loader.load(request);
				}
				catch(err : Error)
				{
					observer.onError(err);
				}
				
				return cancelable;
			});
		}

		/**
		 * Loads an XML document
		 * @param request The URLRequest to load
		 * @param ignoreWhite Whether to ignore whitespace when parsing the XML
		 * @param loaderContext The optional LoaderContext to use
		 * @return An IObservable sequence of XMLDocument 
		 */		
		public static function xml(request : URLRequest, loaderContext : LoaderContext = null) : IObservable
		{
			return urlLoader(request, URLLoaderDataFormat.TEXT, loaderContext)
				.map(function(xml : String) : XML 
				{
					return XML(xml);
				});
		}
	}
}
