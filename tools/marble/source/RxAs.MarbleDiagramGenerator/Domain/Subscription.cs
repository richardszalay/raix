using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace RxAs.MarbleDiagramGenerator.Domain
{
    public class Subscription : MarbleGlyph
    {
        public bool Completes { get; set; }
    }
}
