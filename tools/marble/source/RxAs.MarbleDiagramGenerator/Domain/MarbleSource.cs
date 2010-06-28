using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace RxAs.MarbleDiagramGenerator.Domain
{
    public class MarbleSource
    {
        public string Label { get; set; }

        public IEnumerable<MarbleGlyph> Glyphs { get; set; }
    }
}
