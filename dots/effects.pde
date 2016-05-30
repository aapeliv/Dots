/* Copyright (C) 2016  Aapeli Vuorinen

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>. */

// This effect just makes everything white after the specified time.
class DebugEffect extends Effect {
  float t;

  DebugEffect(float tS) {
    super(tS, 0);
    t = tS;
  }

  Dot Apply(float tt, Dot dot) {
    return (tt > t) ? new Dot(dot.x, dot.y, dot.r, 1, 1, 1) : dot;
  }
}

// Fades out small dots proportional to their radius to the maximum radius
class MainEffect extends Effect {
  float maxRadius;

  MainEffect(float maxRadiusS) {
    super(0, 0);
    maxRadius = maxRadiusS;
  }

  Dot Apply(float t, Dot dot) {
    float pr = dot.r / maxRadius;
    return new Dot(dot.x, dot.y, dot.r, dot.red * pr, dot.green * pr, dot.blue * pr);
  }
}

// Tints the colors
class Tint extends Effect {
  // r, g, b are red, green, blue
  // S = start
  // E = end
  float rS, rE, gS, gE, bS, bE;

  Tint(float rSS, float rES, float gSS, float gES, float bSS, float bES) {
    // Always active
    super(0, 0);
    rS = rSS;
    rE = rES;
    gS = gSS;
    gE = gES;
    bS = bSS;
    bE = bES;
  }

  Dot Apply(float t, Dot dot) {
    // See SmoothTransition
    return new Dot(dot.x, dot.y, dot.r, rS + SmoothTransition(dot.red) * (rE - rS), gS + SmoothTransition(dot.green) * (gE - gS), bS + SmoothTransition(dot.blue) * (bE - bS));
  }
}

// This makes the Dot become smaller and then bigger again
class Retract extends Effect {
  float time, duration, factor;

  Retract(float timeS, float durationS, float factorS) {
    super(timeS, timeS + durationS);
    time = timeS;
    duration = durationS;
    factor = factorS;
  }

  Dot Apply(float t, Dot dot) {
    return new Dot(dot.x, dot.y, dot.r * (1 - factor * Parabola((t - time) / duration)), dot.red, dot.green, dot.blue);
  }
}

// Same as Retract but only applies in a circle of radius r around (x,y)
class RetractCircle extends Effect {
  float time, x, y, r, duration, factor;

  RetractCircle(float timeS, float xS, float yS, float rS, float durationS, float factorS) {
    super(timeS, timeS + durationS);
    time = timeS;
    x = xS;
    y = yS;
    r = rS;
    duration = durationS;
    factor = factorS;
  }

  Dot Apply(float t, Dot dot) {
    if (dot.Dist(x, y) < r) {
      return new Dot(dot.x, dot.y, dot.r * (1 - factor * Parabola((t - time) / duration)), dot.red, dot.green, dot.blue);
    } else {
      return dot;
    }
  }
}

// This creates a kind of "magnification" effect
class Parallax extends Effect {
  float factor, xC, yC, viewRadius;

  Parallax(float factorS, float xCS, float yCS, float viewRadiusS) {
    super(0, 0);
    factor = factorS;
    xC = xCS;
    yC = yCS;
    viewRadius = viewRadiusS;
  }

  void SetCenter(float xCS, float yCS) {
    xC = xCS;
    yC = yCS;
  }

  Dot Apply(float t, Dot dot) {
    float curDist = dot.Dist(xC, yC);
    float xDir = (dot.x - xC) / curDist;
    float yDir = (dot.y - yC) / curDist;
    float newDist = curDist * (1 + factor * SmoothSymmetricBump(curDist / viewRadius));
    return new Dot(xC + xDir * newDist, yC + yDir * newDist, dot.r, dot.red, dot.green, dot.blue);
  }
}

// This was a testing Effect, makes everythign jiggle
class StationaryWave extends Effect {
  StationaryWave() {
    super(0, 0);
  }

  Dot Apply(float t, Dot dot) {
    return new Dot(dot.x + 0.1 * (50 + dot.r) * sin(dot.x + t / 20), dot.y, dot.r, dot.red, dot.green, dot.blue);
  }
}

// This is the basic template for most effects used in the actual video. It just
// computes an intensity factor based on an expanding circle eminating (x,y)
// with a certain size, speed and "fatness" (frontSize).
class Ripple extends Effect {
  float time, x, y, intensity, frontSize, size, speed;
  Ripple(float timeS, float xS, float yS, float intensityS, float frontSizeS, float sizeS, float speedS) {
    super(timeS, timeS + exp(sizeS / speedS));
    time = timeS;
    x = xS;
    y = yS;
    intensity = intensityS;
    frontSize = frontSizeS;
    size = sizeS;
    speed = speedS;
  }

  float ComputePropIntensity(float t, Dot dot) {
    if (t < time) {
      return 0;
    } else {
      float currentRadius = (t - time) * speed;
      float d = dot.Dist(x, y);
      float distToFront = d - currentRadius;
      float sizeFactor = exp(-currentRadius / size);
      return SmoothSymmetricBump(distToFront / frontSize) * sizeFactor;
    }
  }
}

class ContractRipple extends Ripple {
  ContractRipple(float timeS, float xS, float yS, float intensityS, float frontSizeS, float sizeS, float speedS) {
    super(timeS, xS, yS, intensityS, frontSizeS, sizeS, speedS);
  }

  Dot Apply(float t, Dot dot) {
    float curDist = dot.Dist(x, y);
    float xDir = (dot.x - x) / curDist;
    float yDir = (dot.y - y) / curDist;
    float newDist = curDist * (1 - intensity * ComputePropIntensity(t, dot));
    return new Dot(x + xDir * newDist, y + yDir * newDist, dot.r, dot.red, dot.green, dot.blue);
  }
}

// Makes dots bigger in a ripple effect thing
class ZoomRipple extends Ripple {
  ZoomRipple(float timeS, float xS, float yS, float intensityS, float frontSizeS, float sizeS, float speedS) {
    super(timeS, xS, yS, intensityS, frontSizeS, sizeS, speedS);
  }

  Dot Apply(float t, Dot dot) {
    return new Dot(dot.x, dot.y, (1 + intensity * ComputePropIntensity(t, dot)) * dot.r, dot.red, dot.green, dot.blue);
  }
}

// Makes dots brighter in a ripple effect thing
class FlashRipple extends Ripple {
  FlashRipple(float timeS, float xS, float yS, float intensityS, float frontSizeS, float sizeS, float speedS) {
    super(timeS, xS, yS, intensityS, frontSizeS, sizeS, speedS);
  }

  Dot Apply(float t, Dot dot) {
    float factor = 1 + intensity * ComputePropIntensity(t, dot);
    return new Dot(dot.x, dot.y, dot.r, dot.red * factor, dot.green * factor, dot.blue * factor);
  }
}

// Makes only smaller dots brighter in a ripple effect thing
class SmallDotsFlashRipple extends Ripple {
  float maxRadius, minRadius;

  SmallDotsFlashRipple(float timeS, float xS, float yS, float intensityS, float frontSizeS, float sizeS, float speedS, float maxRadiusS, float minRadiusS) {
    super(timeS, xS, yS, intensityS, frontSizeS, sizeS, speedS);
    maxRadius = maxRadiusS;
    minRadius = minRadiusS;
  }

  Dot Apply(float t, Dot dot) {
    float f = intensity * ComputePropIntensity(t, dot) * SmoothTransition(1 - (dot.r - minRadius) / (maxRadius - minRadius + 1));
    return new Dot(dot.x, dot.y, dot.r, f + dot.red, f + dot.green, f + dot.blue);
  }
}

// Makes only smaller dots brighter in a ripple effect thing
class SmallDotsFlashBottom extends Effect {
  float time, x, y, intensity, frontSize, size, speed;

  float ComputePropIntensity(float t, Dot dot) {
    if (t < time) {
      return 0;
    } else {
      float tElapsed = t - time;
      float currentRadius = tElapsed * speed;
      //float d = (dot.x < x;f
      float d = dot.Dist(x, y);
      float distToFront = d - currentRadius;
      float sizeFactor = (size == 0) ? 1 : exp(-currentRadius / size);
      return SmoothSymmetricBump(distToFront / frontSize) * sizeFactor;
    }
  }

  SmallDotsFlashBottom(float timeS, float intensityS, float frontSizeS, float sizeS, float speedS, float maxRadiusS, float minRadiusS, float x) {
    super(timeS, timeS + sizeS / speedS);
    time = timeS;
    intensity = intensityS;
    frontSize = frontSizeS;
    size = sizeS;
    speed = speedS;
    maxRadius = maxRadiusS;
    minRadius = minRadiusS;
  }

  Dot Apply(float t, Dot dot) {
    float f = intensity * ComputePropIntensity(t, dot) * SmoothTransition(1 - (dot.r - minRadius) / (maxRadius - minRadius + 1));
    return new Dot(dot.x, dot.y, dot.r, f + dot.red, f + dot.green, f + dot.blue);
  }
}

// Makes small dots bigger in a ripple effect thing
class SmallDotsZoomRipple extends Ripple {
  float maxRadius, minRadius;
  SmallDotsZoomRipple(float timeS, float xS, float yS, float intensityS, float frontSizeS, float sizeS, float speedS, float maxRadiusS, float minRadiusS) {
    super(timeS, xS, yS, intensityS, frontSizeS, sizeS, speedS);
    maxRadius = maxRadiusS;
    minRadius = minRadiusS;
  }

  Dot Apply(float t, Dot dot) {
    float f = 1 + intensity * ComputePropIntensity(t, dot) * SmoothTransition(1 - (dot.r - minRadius) / (maxRadius - minRadius));
    return new Dot(dot.x, dot.y, dot.r * f, dot.red, dot.green, dot.blue);
  }
}

// Makes small dots bigger in a ripple effect thing
class BigBallsContractRipple extends Ripple {
  float maxRadius, minRadius;
  BigBallsContractRipple(float timeS, float xS, float yS, float intensityS, float frontSizeS, float sizeS, float speedS, float maxRadiusS, float minRadiusS) {
    super(timeS, xS, yS, intensityS, frontSizeS, sizeS, speedS);
    maxRadius = maxRadiusS;
    minRadius = minRadiusS;
  }

  Dot Apply(float t, Dot dot) {
    float f = 1 - intensity * ComputePropIntensity(t, dot) * SmoothTransition((dot.r - minRadius) / (maxRadius - minRadius));
    return new Dot(dot.x, dot.y, dot.r * f, dot.red, dot.green, dot.blue);
  }
}
