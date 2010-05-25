package samples.imageSearch
{
	import flash.events.Event;
	
	import mx.controls.Image;
	
	import rx.IObservable;
	import rx.Observable;
	
	public class ImageResultLoaderService
	{
		private static const PRELOAD_TIMEOUT : int = 3000;
		
		public function ImageResultLoaderService()
		{
		}
		
		public function getObservable(source : IObservable, thumbnail : Boolean, preload : Boolean) : IObservable
		{
			return source
				.select(Image, function(result : ImageResult) : Image
				{
					return createImage(result, thumbnail);
				})
				.let(function(obs : IObservable) : IObservable
				{
					return preload
						? preloadImages(obs)
						: obs;
				});
		}
		
		private function createImage(result : ImageResult, thumbnail : Boolean) : Image
		{
			var image : Image = new Image();
					
			var url : String = thumbnail
				? result.thumbnailUrl
				: result.url;
			
			image.load(url);
			
			return image;
		}
		
		private function preloadImages(observable : IObservable) : IObservable
		{
			return observable
				.selectMany(Image, function(image:Image) : IObservable
				{
					return Observable.fromEvent(image, Event.COMPLETE)
						.select(Image, function():Image { return image; })
						.take(1)
						.timeout(PRELOAD_TIMEOUT)
						.catchError(Observable.empty(Image));
				});
		}
	}
}