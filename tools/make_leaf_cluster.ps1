param([string]$Leaves = "LeafSet024", [string]$Out = "leaf_cluster", [int]$Seed = 7)
# Builds a 1024x1024 RGBA texture with 4 leafy twigs (2x2 atlas) out of the single leaves in an
# ambientCG leaf set (3x3 leaves, color + opacity). Used for the tree crown cards (nature.gd).
$root = Split-Path $PSScriptRoot -Parent
$tex = Join-Path $root "assets\textures"
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class LeafCluster {
    static Bitmap Shrink(string path, int size) {
        using (var src = Image.FromFile(path)) {
            var b = new Bitmap(size, size, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(b)) { g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.DrawImage(src, 0, 0, size, size); }
            return b;
        }
    }
    public static void Make(string color, string opacity, string outPath, int seed) {
        const int S = 600, C = 200;   // 3x3 cells of 200 px
        var col = Shrink(color, S);
        var op = Shrink(opacity, S);
        var leaves = new Bitmap[9];
        for (int i = 0; i < 9; i++) {
            var l = new Bitmap(C, C, PixelFormat.Format32bppArgb);
            int ox = (i % 3) * C, oy = (i / 3) * C;
            for (int y = 0; y < C; y++) for (int x = 0; x < C; x++) {
                Color c = col.GetPixel(ox + x, oy + y);
                int a = op.GetPixel(ox + x, oy + y).R;
                l.SetPixel(x, y, Color.FromArgb(a < 40 ? 0 : a, c.R, c.G, c.B));
            }
            leaves[i] = l;
        }
        var rnd = new Random(seed);
        var outBmp = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(outBmp)) {
            g.Clear(Color.FromArgb(0, 70, 90, 40));
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            for (int q = 0; q < 4; q++) {
                float qx = (q % 2) * 512, qy = (q / 2) * 512;
                var clip = new Rectangle((int)qx + 4, (int)qy + 4, 504, 504);
                g.SetClip(clip);
                // twigs: a stem from the bottom centre fanning out into 5-6 sprigs
                var tips = new System.Collections.Generic.List<PointF[]>();
                PointF basePt = new PointF(qx + 256, qy + 500);
                int sprigs = 6 + rnd.Next(2);
                for (int s = 0; s < sprigs; s++) {
                    double ang = -Math.PI / 2 + (s - (sprigs - 1) / 2.0) * 0.42 + (rnd.NextDouble() - 0.5) * 0.2;
                    float len = 230 + (float)rnd.NextDouble() * 100;
                    PointF mid = new PointF(qx + 256 + (float)Math.Cos(ang) * 60, qy + 430 + (float)Math.Sin(ang) * 60);
                    PointF tip = new PointF(mid.X + (float)Math.Cos(ang) * len, mid.Y + (float)Math.Sin(ang) * len);
                    tips.Add(new PointF[] { mid, tip });
                    using (var pen = new Pen(Color.FromArgb(255, 74, 56, 38), 5f)) { g.DrawLine(pen, basePt, mid); }
                    using (var pen = new Pen(Color.FromArgb(255, 84, 64, 44), 3f)) { g.DrawLine(pen, mid, tip); }
                }
                // leaves along the sprigs, back (darker) to front (lighter)
                int count = 95;
                for (int k = 0; k < count; k++) {
                    var sp = tips[rnd.Next(tips.Count)];
                    float t = 0.1f + (float)rnd.NextDouble() * 0.95f;
                    float px = sp[0].X + (sp[1].X - sp[0].X) * t, py = sp[0].Y + (sp[1].Y - sp[0].Y) * t;
                    double dir = Math.Atan2(sp[1].Y - sp[0].Y, sp[1].X - sp[0].X);
                    double side = rnd.Next(2) == 0 ? -1 : 1;
                    double a = dir + side * (0.6 + rnd.NextDouble() * 0.7);
                    float size = 70 + (float)rnd.NextDouble() * 55;
                    float depth = (float)k / count;
                    float br = 0.55f + depth * 0.5f + (float)(rnd.NextDouble() - 0.5) * 0.15f;
                    float yel = (float)rnd.NextDouble() * 0.12f;
                    var cm = new ColorMatrix(new float[][] {
                        new float[] { br * (1 + yel), 0, 0, 0, 0 },
                        new float[] { 0, br, 0, 0, 0 },
                        new float[] { 0, 0, br * 0.9f, 0, 0 },
                        new float[] { 0, 0, 0, 1, 0 },
                        new float[] { 0, 0, 0, 0, 1 } });
                    using (var ia = new ImageAttributes()) {
                        ia.SetColorMatrix(cm);
                        var st = g.Save();
                        g.TranslateTransform(px, py);
                        // the leaf images point up (tip at the top, stalk at the bottom)
                        g.RotateTransform((float)(a * 180 / Math.PI) + 90);
                        float w = size * 0.8f, h = size;
                        var dst = new Point[] { new Point((int)(-w / 2), (int)-h), new Point((int)(w / 2), (int)-h), new Point((int)(-w / 2), 0) };
                        g.DrawImage(leaves[rnd.Next(9)], dst, new Rectangle(0, 0, C, C), GraphicsUnit.Pixel, ia);
                        g.Restore(st);
                    }
                }
                g.ResetClip();
            }
        }
        // bleed colour into transparent pixels so mipmaps don't get dark halos
        var bleed = new Bitmap(outBmp);
        for (int y = 0; y < 1024; y++) for (int x = 0; x < 1024; x++) {
            Color c = outBmp.GetPixel(x, y);
            if (c.A < 20) bleed.SetPixel(x, y, Color.FromArgb(c.A, 62, 78, 34));
        }
        bleed.Save(outPath, ImageFormat.Png);
    }

    // Conifer spray: a branch running from the bottom (trunk) to the top (tip) of each cell with
    // side twigs, all covered in short needles. 2x2 variants.
    public static void MakePine(string outPath, int seed) {
        var rnd = new Random(seed);
        var bmp = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) {
            g.Clear(Color.FromArgb(0, 40, 62, 30));
            g.SmoothingMode = SmoothingMode.AntiAlias;
            for (int q = 0; q < 4; q++) {
                float qx = (q % 2) * 512, qy = (q / 2) * 512;
                g.SetClip(new Rectangle((int)qx + 3, (int)qy + 3, 506, 506));
                var twigs = new System.Collections.Generic.List<PointF[]>();
                PointF a0 = new PointF(qx + 256, qy + 505), a1 = new PointF(qx + 256 + (float)(rnd.NextDouble() - 0.5) * 30, qy + 30);
                twigs.Add(new PointF[] { a0, a1 });
                for (int s = 0; s < 9; s++) {
                    float t = 0.15f + s * 0.09f;
                    PointF o = new PointF(a0.X + (a1.X - a0.X) * t, a0.Y + (a1.Y - a0.Y) * t);
                    float side = s % 2 == 0 ? -1 : 1;
                    float len = (1.0f - t) * 260 + 50;
                    double ang = -Math.PI / 2 + side * (0.75 + rnd.NextDouble() * 0.3);
                    twigs.Add(new PointF[] { o, new PointF(o.X + (float)Math.Cos(ang) * len, o.Y + (float)Math.Sin(ang) * len) });
                }
                foreach (var tw in twigs) {
                    using (var pen = new Pen(Color.FromArgb(255, 70, 52, 36), tw == twigs[0] ? 6f : 3f)) g.DrawLine(pen, tw[0], tw[1]);
                }
                // needles: back layer darker, front layer lighter
                for (int layer = 0; layer < 2; layer++) {
                    foreach (var tw in twigs) {
                        float dx = tw[1].X - tw[0].X, dy = tw[1].Y - tw[0].Y;
                        float L = (float)Math.Sqrt(dx * dx + dy * dy);
                        double dir = Math.Atan2(dy, dx);
                        int n = (int)(L / 3.2f);
                        for (int k = 0; k < n; k++) {
                            float t = (float)k / n;
                            float px = tw[0].X + dx * t, py = tw[0].Y + dy * t;
                            for (int sd = -1; sd <= 1; sd += 2) {
                                double na = dir + sd * (0.75 + rnd.NextDouble() * 0.35) - 0.25;
                                float nl = (layer == 0 ? 30 : 24) * (0.75f + (float)rnd.NextDouble() * 0.5f) * (1.0f - t * 0.35f);
                                int gch = (layer == 0 ? 62 : 92) + rnd.Next(26);
                                var col = Color.FromArgb(255, (int)(gch * 0.55), gch, (int)(gch * 0.42));
                                using (var pen = new Pen(col, layer == 0 ? 3.2f : 2.4f)) {
                                    pen.StartCap = LineCap.Round; pen.EndCap = LineCap.Round;
                                    g.DrawLine(pen, px, py, px + (float)Math.Cos(na) * nl, py + (float)Math.Sin(na) * nl);
                                }
                            }
                        }
                    }
                }
                g.ResetClip();
            }
        }
        var bleed = new Bitmap(bmp);
        for (int y = 0; y < 1024; y++) for (int x = 0; x < 1024; x++) {
            Color c = bmp.GetPixel(x, y);
            if (c.A < 20) bleed.SetPixel(x, y, Color.FromArgb(c.A, 40, 62, 30));
        }
        bleed.Save(outPath, ImageFormat.Png);
    }
}
"@
[LeafCluster]::Make((Join-Path $tex "$($Leaves)_color.jpg"), (Join-Path $tex "$($Leaves)_opacity.jpg"), (Join-Path $tex "$Out.png"), $Seed)
"wrote $Out.png"
[LeafCluster]::MakePine((Join-Path $tex "pine_cluster.png"), $Seed)
"wrote pine_cluster.png"

