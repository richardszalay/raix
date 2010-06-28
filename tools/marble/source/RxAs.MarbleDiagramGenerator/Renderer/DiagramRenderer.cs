using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Media.Imaging;
using System.Windows.Media;

namespace RxAs.MarbleDiagramGenerator.Renderer
{
    public class DiagramRenderer
    {
        private int width = 640;
        private int height = 480;
        private const int Dpi = 96;

        public void RenderImage(Domain.MarbleDiagram diagram, string outputImage)
        {
            PixelFormat pf = PixelFormats.Rgb24;

            int rawStride = (width * pf.BitsPerPixel + 7) / 8;
            byte[] pixels = new byte[rawStride * height];

            BitmapSource bitmap = BitmapSource.Create(width, height, Dpi, Dpi,
                PixelFormats.Rgb24, BitmapPalettes.Halftone64Transparent,
                pixels, rawStride);

            //RenderTargetBitmap
        }
    }
}
