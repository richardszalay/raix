package samples.imageSearch
{
	public class ImageResult
	{
		private var _url : String;
		private var _thumbnailUrl : String;
		private var _description : String;
		
		public function ImageResult(url : String, thumbnailUrl : String, description : String)
		{
			this._url = url;
			this._thumbnailUrl = thumbnailUrl;
			this._description = description;
		}
		
		public function get url() : String { return _url; }
		public function get thumbnailUrl() : String { return _thumbnailUrl; }
		public function get description() : String { return _description; }
	}
}