/*
  string_hanging_and_big_ball.pde
  
 - Akira Kageyama (kage@port.kobe-u.ac.jp)
 
 - History
           2026.04.12: cp and revise string_catenary2.pde. 
                       This is string_tension_transverse_wave.           
           2026.04.23: Rename from sring_tension_transverse_wave.
                       This is string_tension_transverse_wave_resonance.
           2026.04.23: Rename string_catenary. This is string_catenary. 
           2026.04.25: cp from string_catenary. This is string_hanging.
           2026.04.27: cp from string_hanging. This is string_and_bib_ball
  

 - Note
         - Release an end point from the ceiling.
 
 - Usage 
           Mouse click : 
               1st click --> Start calculation
               2nd click --> Release the end point
               3rd click --> Throw the big ball
               4th click --> Stop calculation
               5th and later --> Start/stop toggle
 
 */


// When NUM_OF_STRING_PARTICLES = 6
//
//   Before ReleaseStringEndParticle
//
//         ...............0.....................5.....
//                         .                   .
//                          1                 4           
//                            .             .
//                                2  .  3       
//     
//    
//    
//                                                    .  .
//                                                  .      .
//                                                 .  Big   .
//                                                 .  Ball  .
//                                                  .      .
//                                                    .  .  
//    
//    
//    
//    
//     
//   After ReleaseStringEndParticle
//
//         ...............0............................
//                         .          
//                          1                  
//                            .               
//                              2              5
//                                 .          .
//                                    3  .  4
//                            
//         
//    
//                                                    .  .
//                                                  .      .
//                                                 .  Big   .
//                                                 .  Ball  .
//                                                  .      .
//                                                    .  .  
//    
//     
//   After the hanging relaxation
//
//         ...............0............................
//                        .          
//                        .          
//                        1                  
//                        .               
//                        .               
//                        2
//                        .
//                        .
//                        3
//                        .              Though the big ball.
//                        .                     __
//                        4                    |\
//                        .                      \
//                        .                       \
//                        5                           .  .
//                                                  .      .
//                                                 .  Big   .
//                                                 .  Ball  .
//                                                  .      .
//                                                    .  .  
//    
//     


//--------------------<input parameters>--------------------
//
//---<String>---
final int   NUM_OF_STRING_PARTICLES = 31;     // When odd --> triangle, even --> semi-circle.
final float STRING_LENGTH           = 2.0;    // (m)
final float STRING_MASS             = 0.005;  // (kg)
final float STRING_PARTICLE_MASS    = STRING_MASS / NUM_OF_STRING_PARTICLES;
final float STRING_PARTICLE_RADIUS  = 0.01;   // (m)

final float SPRING_NATURAL_LENGTH = STRING_LENGTH / (NUM_OF_STRING_PARTICLES-1);
final float STRING_SPRING_CHAR_PERIOD = 0.004; // (sec)
final float STRING_SPRING_CHAR_OMEGA = TWO_PI / STRING_SPRING_CHAR_PERIOD;
final float STRING_SPRING_CHAR_OMEGA_SQ = STRING_SPRING_CHAR_OMEGA*STRING_SPRING_CHAR_OMEGA; // omega^2 = k/m
final float STRING_SPRING_CONST = STRING_PARTICLE_MASS * STRING_SPRING_CHAR_OMEGA_SQ;  // k = m*omega^2
//---</String>---



//---<Parameters>---
final float GRAVITY_ACCELERATION = 9.8067;
final int DISPLAY_SPEED = 200;  // the larger, the quicker.

boolean RunningStateToggle = false;
boolean DrawSolutionCurvesToggle = true;
boolean ReleaseStringEndParticle = false;
boolean ThrowBiGBall = false;
//---</Parameters>---


//---<Big Balls>---
final int   NUM_OF_BIG_BALLS = 5;
final float BIG_BALL_INITIAL_THROW_VELOCITY = 1.0; // (m)/(sec)
final float BIG_BALL_RADIUS = 0.05;  // (m)
final float BIG_BALL_MASS = STRING_MASS*2;  // (kg); Heavy.
final float BIG_BALL_INTERNAL_SPRING_CONST = STRING_SPRING_CONST*10;
final float BIG_BALL_INTERNAL_SPRING_CHAR_OMEGA_SQ 
              = BIG_BALL_INTERNAL_SPRING_CONST / BIG_BALL_MASS;
                                        // (sec)^{-2}
final float BIG_BALL_INTERNAL_SPRING_CHAR_OMEGA 
              = sqrt(BIG_BALL_INTERNAL_SPRING_CHAR_OMEGA_SQ);
                                        // (sec)^{-1}
final float BIG_BALL_INTERNAL_SPRING_CHAR_PERIOD
              = TWO_PI / BIG_BALL_INTERNAL_SPRING_CHAR_OMEGA;
//---</Big Balls>---
                                        // (sec)
//-------------------</input parameters>--------------------

final int NUM_OF_ALL_PARTICLES = NUM_OF_STRING_PARTICLES + NUM_OF_BIG_BALLS;

float[] particlePosX = new float[NUM_OF_ALL_PARTICLES];
float[] particlePosY = new float[NUM_OF_ALL_PARTICLES];
float[] particleVelX = new float[NUM_OF_ALL_PARTICLES];
float[] particleVelY = new float[NUM_OF_ALL_PARTICLES];

float[] stringSpringK = new float[NUM_OF_STRING_PARTICLES-1];

float[] collidingForceOfStringParticleWithBigBallsX = new float[NUM_OF_STRING_PARTICLES];
float[] collidingForceOfStringParticleWithBigBallsY = new float[NUM_OF_STRING_PARTICLES];



//                          stringFootPointSeparation
//                         /
//                 LeftX  /     RightX
//                /      /     /
//               |<---------->|
//         ......o............o......... x
//                \          / 
//                 o        o
//                  \      / 
//                   o----o
//                         
float stringFootPointSeparation = (STRING_LENGTH/PI) * 2;
float stringFootPointRightX = stringFootPointSeparation/2;
float stringFootPointLeftX = -stringFootPointRightX;

float xmin = -2.0;  // (m)
float xmax =  2.0;
float ymin = -2.5;
float ymax =  0.5;


float dt_string_spring = STRING_SPRING_CHAR_PERIOD*0.1;
float dt_big_ball_internal_spring = BIG_BALL_INTERNAL_SPRING_CHAR_PERIOD*0.1;

// Estimation of maximum velocity of free-falling Big Ball.
//    Total energy = (big_ball_mass/2)*(throw_vel)^2 + (big_ball_mass)*g*ymax
//    Maximum velocity at the floor = sqrt(2*(Total energy)/m)

float initial_big_ball_kinetic_energy = 0.5 * BIG_BALL_MASS * pow( BIG_BALL_INITIAL_THROW_VELOCITY, 2 ); 
float initial_big_ball_potential_energy_max = BIG_BALL_MASS * GRAVITY_ACCELERATION * (ymax-ymin);
float ititial_big_ball_total_energy_max  
        = initial_big_ball_kinetic_energy + initial_big_ball_potential_energy_max; 
float big_ball_free_fall_max_velocity_on_floor 
        = sqrt( 2 * ititial_big_ball_total_energy_max / BIG_BALL_MASS );
float big_ball_free_fall_characteristic_time_scale 
        = BIG_BALL_RADIUS / big_ball_free_fall_max_velocity_on_floor;

float dt_big_ball_resolve_collision_with_floor = big_ball_free_fall_characteristic_time_scale*0.1;

float time = 0.0; // (sec)
int   step = 0;

float dt = min( dt_string_spring,
                dt_big_ball_internal_spring,
                dt_big_ball_resolve_collision_with_floor );  // (sec)


void initialize() 
{  
  for (int i=0; i<NUM_OF_STRING_PARTICLES-1; i++) {
    stringSpringK[i] = STRING_SPRING_CONST;
  }

  particlePosX[0] = stringFootPointLeftX; // x coord
  particlePosY[0] = 0.0; // y coord
  particleVelX[0] = 0.0; // vx
  particleVelY[0] = 0.0; // vy

  if ( NUM_OF_STRING_PARTICLES % 2 == 0 ) {
    string_initial_curve_single_semi_circle();
  } else {  
   string_initial_curve_triangle();
  }

  big_balls_initial_condition();
}


void string_initial_curve_single_semi_circle()
{
  /*
         .       .
          .     .
            . .
  */
  
  for (int i=1; i<NUM_OF_STRING_PARTICLES; i++) {
    float angle = i*(PI/(NUM_OF_STRING_PARTICLES-1));
    float radius = stringFootPointSeparation / 2;
    particlePosX[i] = -radius*cos(angle);  // x
    particlePosY[i] = -radius*sin(angle);  // y
    particleVelX[i] = 0.0; // vx
    particleVelY[i] = 0.0; // vy
  }
}

void string_initial_curve_triangle()
{
  /*
       When NUM_OF_STRING_PARTICLES = 7
         
                        _
         .           .   |
           .       .     |
             .   .       |  triangle height
               .        _|
               
         |           |
         |-----------|
               \
                \___ stringFootPointSeparation
               
               
       We focus on the left-half.
       
                 ___  edge1 = (length=stringFootPointSeparation/2)           
                /
            |-----|
            .......
           /  .   .
          /     . .
         e        .
           d     /
             g  /
               e
                 2
       */
       
  float l0 = SPRING_NATURAL_LENGTH;
  final int MID_PARTICLE = NUM_OF_STRING_PARTICLES / 2;  
         // Here we assume NUM_OF_STRING_PARTICLES is odd.
         // When NUM_OF_STRING_PARTICLES = 7, MID_PARTICLE = 3.
  float triangle_edge1_length = stringFootPointSeparation / 2;
  float triangle_edge2_length = l0 * MID_PARTICLE;
  float cos_phi = triangle_edge1_length / triangle_edge2_length;
  float sin_phi = sqrt(1-pow(cos_phi,2));
  float delta_x = l0*cos_phi;
  float delta_y = l0*sin_phi;
  
  float x0 = stringFootPointLeftX;
  float y0 = 0;
  
  for (int i=1; i<=MID_PARTICLE; i++) {
    x0 = particlePosX[i] = x0 + delta_x; 
    y0 = particlePosY[i] = y0 - delta_y;
    particleVelX[i] = 0.0; // vx
    particleVelY[i] = 0.0; // vy
  }
  
  for (int i=MID_PARTICLE+1; i<NUM_OF_STRING_PARTICLES; i++) {
    x0 = particlePosX[i] = x0 + delta_x; 
    y0 = particlePosY[i] = y0 + delta_y;
    particleVelX[i] = 0.0; // vx
    particleVelY[i] = 0.0; // vy
  }
}


void big_balls_initial_condition()
{
  int shift = NUM_OF_STRING_PARTICLES;

  for ( int j=0; j<NUM_OF_BIG_BALLS; j++ ) {
    int jshift = j + shift;
    float temp_x = random(xmin*0.8,xmax*0.8);
    float temp_y = random(ymin*0.8,ymax*0.8);
    float minimum_distance_to_other_balls = 0.0;
    while ( minimum_distance_to_other_balls < 1.1*BIG_BALL_RADIUS ) {
      minimum_distance_to_other_balls = 1.e30;  // any huge number
      temp_x = random(xmin*0.8,xmax*0.8); // any 
      temp_y = random(ymin*0.8,ymax*0.8);
      for ( int jj=0; jj<j; jj++ ) {  // survey other balls generated so far
        int jjshift = jj + shift;
        float prev_x = particlePosX[jjshift];
        float prev_y = particlePosY[jjshift];
        minimum_distance_to_other_balls = min( minimum_distance_to_other_balls,
                                               dist( prev_x, prev_y, temp_x, temp_y ) );  
      }
    }
        
    particlePosX[jshift] = temp_x;
    particlePosY[jshift] = temp_y;
    particleVelX[jshift] = BIG_BALL_INITIAL_THROW_VELOCITY*cos(random(TWO_PI));
    particleVelY[jshift] = BIG_BALL_INITIAL_THROW_VELOCITY*sin(random(TWO_PI));
  }
}


void setup() {
  size(500, 500);
  background(255);
  initialize();
  frameRate(60);
}


float totalEnergy()
{
  float energy_of_string = totalEnergyString();
  float energy_of_bib_balls = totalEnergyBigBalls();
  return energy_of_string + energy_of_bib_balls;
}


float totalEnergyString()
{
  float kineticEnergy = 0.0;
  float potentialEnergy = 0.0;
  
  for (int i=0; i<NUM_OF_STRING_PARTICLES; i++) {
    float velx = particleVelX[i];
    float vely = particleVelY[i];
    float posx = particlePosX[i];
    float posy = particlePosY[i];
  
    kineticEnergy += 0.5*STRING_PARTICLE_MASS*(velx*velx+vely*vely);

    if ( i>0 ) {
      float posx0 = particlePosX[i-1];
      float posy0 = particlePosY[i-1];      
      float l = dist(posx,posy,posx0,posy0) - SPRING_NATURAL_LENGTH;
      float lsq = l*l;
      potentialEnergy += 0.5*stringSpringK[i-1]*lsq; 
    }
    
    potentialEnergy += STRING_PARTICLE_MASS*GRAVITY_ACCELERATION*posy;
  }

  return(kineticEnergy + potentialEnergy);
}

float totalEnergyBigBalls()
{
  float kineticEnergy = 0.0;
  float potentialEnergy = 0.0;
  
  for (int j=0; j<NUM_OF_BIG_BALLS; j++) {
    int jshift = NUM_OF_STRING_PARTICLES + j;
    float velx = particleVelX[jshift];
    float vely = particleVelY[jshift];
    float posx = particlePosX[jshift];
    float posy = particlePosY[jshift];
  
    kineticEnergy += 0.5*BIG_BALL_MASS*(velx*velx+vely*vely);
    potentialEnergy += BIG_BALL_MASS*GRAVITY_ACCELERATION*posy;
  }

  return(kineticEnergy + potentialEnergy);
}



void equationOfMotion(float  posx[],
                      float  posy[],
                      float  velx[],
                      float  vely[],                      
                      float dposx[],
                      float dposy[],
                      float dvelx[],
                      float dvely[],
                      float dt) 

{
  // Call equationOfMotionBigBalls before
  // equationOfMotionString because collision is
  // calculated in the former funciton.
  equationOfMotionBigBalls( posx, posy, velx, vely,                      
                            dposx, dposy, dvelx, dvely, dt );

  equationOfMotionString( posx, posy, velx, vely,                      
                          dposx, dposy, dvelx, dvely, dt );
}


void equationOfMotionString(float  posx[],
                            float  posy[],
                            float  velx[],
                            float  vely[],                      
                            float dposx[],
                            float dposy[],
                            float dvelx[],
                            float dvely[],
                            float dt) 

{
  float l0 = SPRING_NATURAL_LENGTH;
  float dtm = dt / STRING_PARTICLE_MASS;
    
  for (int i=1; i<NUM_OF_STRING_PARTICLES; i++) {  
             // See boundaryCondition() for i=0 & NSP-1.   

    // Before ReleaseStringEndParticle
    //
    //       ...............0.....................5.....
    //                       .                   .
    //                        1                 4           
    //                          .             .
    //                              2  .  3       
    //   
    //  
    //   
    // After ReleaseStringEndParticle
    //
    //       ...............0............................
    //                       .          
    //                        1                  
    //                          .               
    //                            2              5
    //                               .          .
    //                                  3  .  4
    //                          
    //       
    //       
    
    //float frictionCoeff = 0;  // No friction
    float frictionCoeff = 0.0001;
      
    float force_x = Float.NaN;
    float force_y = Float.NaN;

    if ( i < NUM_OF_STRING_PARTICLES-1 )  // Skip the end particle.
    {  
      float x0 = posx[i-1];
      float x1 = posx[i  ];
      float x2 = posx[i+1];
      float y0 = posy[i-1];
      float y1 = posy[i  ];
      float y2 = posy[i+1];
      float dist01 = dist(x0,y0,x1,y1);
      float dist12 = dist(x1,y1,x2,y2);

      float s_forceAmp01 = stringSpringK[i-1]*(dist01-l0);
      float s_forceAmp12 = stringSpringK[i  ]*(dist12-l0);
      
      float unitVec01x = (x1-x0)/dist01;
      float unitVec01y = (y1-y0)/dist01;
      float unitVec12x = (x2-x1)/dist12;
      float unitVec12y = (y2-y1)/dist12;
      float s_force01x = s_forceAmp01*unitVec01x;
      float s_force01y = s_forceAmp01*unitVec01y;
      float s_force12x = s_forceAmp12*unitVec12x;
      float s_force12y = s_forceAmp12*unitVec12y;
      float  g_force_y = -STRING_PARTICLE_MASS*GRAVITY_ACCELERATION;

      float v_force_x = -frictionCoeff*velx[i];
      float v_force_y = -frictionCoeff*vely[i];

      force_x = s_force12x - s_force01x + v_force_x;
      force_y = s_force12y - s_force01y + v_force_y + g_force_y;
      
      // Taking the collision with Big Balls into account.      
      force_x += collidingForceOfStringParticleWithBigBallsX[i];
      force_y += collidingForceOfStringParticleWithBigBallsY[i];
    } 
    else if ( i==NUM_OF_STRING_PARTICLES-1 )  // The end particle
    {  
      float x0 = posx[i-1];
      float x1 = posx[i  ];
      float y0 = posy[i-1];
      float y1 = posy[i  ];
      float dist01 = dist(x0,y0,x1,y1);

      float s_forceAmp01 = stringSpringK[i-1]*(dist01-l0);
      
      float unitVec01x = (x1-x0)/dist01;
      float unitVec01y = (y1-y0)/dist01;
      float s_force01x = s_forceAmp01*unitVec01x;
      float s_force01y = s_forceAmp01*unitVec01y;
      float  g_force_y = -STRING_PARTICLE_MASS*GRAVITY_ACCELERATION;

      float v_force_x = -frictionCoeff*velx[i];
      float v_force_y = -frictionCoeff*vely[i];
      
      force_x = -s_force01x + v_force_x;
      force_y = -s_force01y + v_force_y + g_force_y;
      
      // Taking the collision with Big Balls into account.      
      force_x += collidingForceOfStringParticleWithBigBallsX[i];
      force_y += collidingForceOfStringParticleWithBigBallsY[i];      
    } 
    else 
    {
      println("*** Something is strange. ***");
      exit();
    }
    
    
    dposx[i] = velx[i] * dt;  // dx = vx * dt
    dposy[i] = vely[i] * dt;  // dy = vy * dt
    dvelx[i] = force_x * dtm; // dvx = (fx/m)*dt 
    dvely[i] = force_y * dtm; // dvy = (fy/m-g)*dt
  }
}

void equationOfMotionBigBalls( float  posx[],
                               float  posy[],
                               float  velx[],
                               float  vely[],                      
                               float dposx[],
                               float dposy[],
                               float dvelx[],
                               float dvely[],
                               float dt ) 

{
  float dtm = dt / BIG_BALL_MASS;
  float force_x, force_y;

  for (int i=0; i<NUM_OF_STRING_PARTICLES; i++) {
    collidingForceOfStringParticleWithBigBallsX[i] = 0; // reset
    collidingForceOfStringParticleWithBigBallsY[i] = 0;
  }

  for (int j=0; j<NUM_OF_BIG_BALLS; j++) {  
    int jshift = j + NUM_OF_STRING_PARTICLES;

    float[] spring_force_from_rigid_body = new float[2];
    float[] self_pos = new float[2];
    float[] target_rigid_body_pos = new float[2];
    
    force_x = force_y = 0;  // reset
    
    self_pos[0] = posx[jshift];
    self_pos[1] = posy[jshift];

    //---<interaction with spring_particles>---
    for (int i=0; i<NUM_OF_STRING_PARTICLES; i++) {
      target_rigid_body_pos[0] = posx[i]; 
      target_rigid_body_pos[1] = posy[i];
      float contact_radius = STRING_PARTICLE_RADIUS + BIG_BALL_RADIUS;
      spring_force_interacting_with_rigid_body( BIG_BALL_INTERNAL_SPRING_CONST,
                                                contact_radius,
                                                self_pos,
                                                target_rigid_body_pos,
                                                spring_force_from_rigid_body );
      force_x += spring_force_from_rigid_body[0];  
      force_y += spring_force_from_rigid_body[1];  
      // Accumulate the force of this BigBall for all SpringParticles.

      collidingForceOfStringParticleWithBigBallsX[i] -= spring_force_from_rigid_body[0];
      collidingForceOfStringParticleWithBigBallsY[i] -= spring_force_from_rigid_body[1];
        // Law of action and reaction. Accumulate the force for all BigBalls.
    }
    //---</interaction with spring_particles>---

    //---<interaction with other Big Balls>---
    for (int jj=0; jj<NUM_OF_BIG_BALLS; jj++) {
      if ( jj==j ) continue;  // skip self interaction
      int jjshift = jj + NUM_OF_STRING_PARTICLES;

     
      // mid point betwen the big ball pair
      target_rigid_body_pos[0] = ( posx[jjshift] + posx[jshift] ) / 2; 
      target_rigid_body_pos[1] = ( posy[jjshift] + posy[jshift] ) / 2;

      /*
       *
       *        +  +           *  *
       *     +        +     *         *
       *   +            + *             *
       *
       *  +      j       m      jj       *
       *
       *   +            + *             *
       *     +        +     *         *
       *        +  +           *  * 
       *
      */
      float contact_radius = BIG_BALL_RADIUS;
      spring_force_interacting_with_rigid_body( BIG_BALL_INTERNAL_SPRING_CONST,
                                                contact_radius,
                                                self_pos,
                                                target_rigid_body_pos,
                                                spring_force_from_rigid_body );
      force_x += spring_force_from_rigid_body[0];  
      force_y += spring_force_from_rigid_body[1];  
    }

    //---<reflection on the floor (y=ymin)>--- 
    target_rigid_body_pos[0] = self_pos[0];
    target_rigid_body_pos[1] = ymin;
    spring_force_interacting_with_rigid_body( BIG_BALL_INTERNAL_SPRING_CONST,
                                              BIG_BALL_RADIUS,
                                              self_pos,
                                              target_rigid_body_pos,
                                              spring_force_from_rigid_body );
    force_x += spring_force_from_rigid_body[0];                                      
    force_y += spring_force_from_rigid_body[1];                                      
    //---</reflection on the floor (y=ymin)>--- 
                                              

    //---<reflection on the left wall (x=xmin)>--- 
    target_rigid_body_pos[0] = xmin;
    target_rigid_body_pos[1] = self_pos[1];
    spring_force_interacting_with_rigid_body( BIG_BALL_INTERNAL_SPRING_CONST,
                                              BIG_BALL_RADIUS,
                                              self_pos,
                                              target_rigid_body_pos,
                                              spring_force_from_rigid_body );
    force_x += spring_force_from_rigid_body[0];                                      
    force_y += spring_force_from_rigid_body[1];                                      
    //---</reflection on the left wall (x=xmin)>--- 

    //---<reflection on the right wall (x=xmax)>--- 
    target_rigid_body_pos[0] = xmax;
    target_rigid_body_pos[1] = self_pos[1];
    spring_force_interacting_with_rigid_body( BIG_BALL_INTERNAL_SPRING_CONST,
                                              BIG_BALL_RADIUS,
                                              self_pos,
                                              target_rigid_body_pos,
                                              spring_force_from_rigid_body );
    force_x += spring_force_from_rigid_body[0];                                      
    force_y += spring_force_from_rigid_body[1];                                      
    //---</reflection on the right wall (x=xmax)>--- 

    
    float g_force_y = -BIG_BALL_MASS*GRAVITY_ACCELERATION;
    float frictionCoeff = 0.00;  // No friction

    float v_force_x = -frictionCoeff*velx[jshift];
    float v_force_y = -frictionCoeff*vely[jshift];

    force_x += v_force_x;
    force_y += g_force_y + v_force_y;

    dposx[jshift] = velx[jshift] * dt;  // dx = vx * dt
    dposy[jshift] = vely[jshift] * dt;  // dy = vy * dt
    dvelx[jshift] = force_x * dtm; // dvx = (fx/m)*dt 
    dvely[jshift] = force_y * dtm; // dvy = (fy/m-g)*dt
  }
}


void spring_force_interacting_with_rigid_body( float spring_const,
                                               float interaction_distance,
                                               float[] pos_self, 
                                               float[] pos_rigid_body, 
                                               float[] output_force )
{
   float self_x = pos_self[0];
   float self_y = pos_self[1];
   float rigid_body_x = pos_rigid_body[0];
   float rigid_body_y = pos_rigid_body[1];
   float distance_between_self_and_rigid_body = dist( self_x, self_y,
                                                      rigid_body_x, rigid_body_y );
   float force_x = 0;
   float force_y = 0;
   
   if ( distance_between_self_and_rigid_body < interaction_distance ) {
     float spring_shrink_length = interaction_distance - distance_between_self_and_rigid_body;
     float spring_force_amplitude = spring_const * spring_shrink_length;
     float relative_position_unit_vector_x = ( rigid_body_x - self_x ) 
                                             / distance_between_self_and_rigid_body;
     float relative_position_unit_vector_y = ( rigid_body_y - self_y )
                                             / distance_between_self_and_rigid_body;
     force_x = - spring_force_amplitude * relative_position_unit_vector_x;
     force_y = - spring_force_amplitude * relative_position_unit_vector_y;
   }
  
   output_force[0] = force_x;
   output_force[1] = force_y;
}

void boundaryCondition( float t, float[] x, float y[], float[] vx, float[] vy ) 
{
   x[0] = stringFootPointLeftX; // Fix the 1st particle of the string
   y[0] = 0.0;                    
  vx[0] = 0.0;
  vy[0] = 0.0;
  
  if ( !ReleaseStringEndParticle ) {  
     x[NUM_OF_STRING_PARTICLES-1] = stringFootPointRightX;  // Fix the last particle
     y[NUM_OF_STRING_PARTICLES-1] = 0.0;                    // of the string. After
    vx[NUM_OF_STRING_PARTICLES-1] = 0.0;                    // the release, it follows
    vy[NUM_OF_STRING_PARTICLES-1] = 0.0;                    // the equation of motion.
  }
}


float mapx(float x) {
  // (x,y) = physical unit coords. 
  // (map(x),map(y)) = pixel coords.
  float scale = width/(xmax-xmin);
  return map(x, xmin, xmax, scale*xmin, scale*xmax);
}


float mapy(float y) {
  // (x,y) = physical unit coords. 
  // (map(x),map(y)) = pixel coords.
  float scale = height/(ymax-ymin);
  return map(y, ymin, ymax, scale*ymin, scale*ymax);
}



void drawText() {
  fill(0, 0, 0); 
  scale(1, -1);
}


void drawHorizontalLine() 
{
  stroke(200,0,200);
  line(mapx(xmin), mapy(0), mapx(xmax), mapy(0));
  stroke(200,0,0);
  line(mapx(0),mapy(0),mapx(xmin),mapy(0));
}


void drawString() {
  stroke(50, 100, 200);

  for (int i=0; i<NUM_OF_STRING_PARTICLES-1; i++) {
    if ( stringSpringK[i] > 0.0 ) {
      float x0 = particlePosX[i];
      float y0 = particlePosY[i];
      float x1 = particlePosX[i+1];
      float y1 = particlePosY[i+1];
      line(mapx(x0), mapy(y0), mapx(x1), mapy(y1));
    }
  }

  for (int i=0; i<NUM_OF_STRING_PARTICLES; i++) {
    float x = particlePosX[i];
    float y = particlePosY[i];
    circle(mapx(x), mapy(y), mapx(STRING_PARTICLE_RADIUS*2)); // 3rd arg is diameter.
  }
}


void drawBigBalls() {
  stroke(0);
  fill(210, 250, 70); 

  for (int j=0; j<NUM_OF_BIG_BALLS; j++) {
    int jshift = NUM_OF_STRING_PARTICLES + j;
    float x = particlePosX[jshift];
    float y = particlePosY[jshift];
    circle(mapx(x), mapy(y), mapx(BIG_BALL_RADIUS*2)); // 3rd arg is diameter.
  }
}


float cosh(float x) {
  return (exp(x)+exp(-x))/2;  
}


float catenaryCurve(float c1, float x1, float x) {
  return c1*(cosh(x/c1) - cosh(x1/c1));
}


void drawSingleSolutionCurveOfCatenary(float param_c1) {
  int npoint = 20;

  float dx = (stringFootPointRightX-stringFootPointLeftX)/(npoint-1);
  
  stroke(255,220,110);

  float x0 = stringFootPointLeftX;
  float y0 = catenaryCurve(param_c1, stringFootPointRightX, x0);
  
  for (int i=1; i<npoint; i++) {
    float x1 = stringFootPointLeftX + dx*i;
    float y1 = catenaryCurve(param_c1, stringFootPointLeftX, x1);
    line(mapx(x0), mapy(y0), mapx(x1), mapy(y1));
    x0 = x1;
    y0 = y1;
  }
}


void drawSolutionCurvesOfCatenary() {
  float param_c1_min = 0.3;
  float param_c1_max = 0.5;
  int ncurves = 10;
  
  for (int n=0; n<10; n++) {
    float param_c1 = param_c1_min + n*(param_c1_max-param_c1_min)/(ncurves-1);    
    drawSingleSolutionCurveOfCatenary( param_c1 );
  }
}


void draw() 
{
  background(255);
  stroke(0, 0, 255);

  translate(width/2, height*ymax/(ymax-ymin));
  scale(1, -1);

  if ( DrawSolutionCurvesToggle ) {
    drawSolutionCurvesOfCatenary();
  }
  drawString();
  drawHorizontalLine();

  drawBigBalls();

  if ( RunningStateToggle ) {
    for (int n=0; n<20; n++) { // to speed up the display
      rungeKutta4();
      step += 1;
      if ( step%100 == 0 ) {
        println("step=", nf(step,9), 
                "time=", nf(time,1,6), 
                "energy=", totalEnergy() );                
      }
    }
  }
  drawText();
}


void mousePressed() {
  if ( !RunningStateToggle && !ReleaseStringEndParticle ) { // Initial state
    RunningStateToggle = true;
    return;
  } 
    
  if ( RunningStateToggle && !ReleaseStringEndParticle ) {  // Release 
    ReleaseStringEndParticle = true;
    DrawSolutionCurvesToggle = false;
    return;
  }
  
  RunningStateToggle = !RunningStateToggle;
}
