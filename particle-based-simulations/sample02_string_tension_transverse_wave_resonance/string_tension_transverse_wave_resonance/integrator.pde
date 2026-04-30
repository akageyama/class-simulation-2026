
void rungeKutta4Advance(int num, 
                        float[] posx,
                        float[] posy,
                        float[] velx,
                        float[] vely,
                        float[] posx1,
                        float[] posy1,
                        float[] velx1,
                        float[] vely1,
                        float[] dposx,
                        float[] dposy,
                        float[] dvelx,
                        float[] dvely,
                        float factor)
{
  for (int j=0; j<num; j++) {
    posx[j] = posx1[j] + factor*dposx[j];
    posy[j] = posy1[j] + factor*dposy[j];
    velx[j] = velx1[j] + factor*dvelx[j];
    vely[j] = vely1[j] + factor*dvely[j];
  }
}



void rungeKutta4()
{
  final float ONE_SIXTH = 1.0/6.0;
  final float ONE_THIRD = 1.0/3.0;

  float[] posxprev = new float[NUM_OF_PARTICLES];
  float[] posxwork = new float[NUM_OF_PARTICLES];
  float[]   dposx1 = new float[NUM_OF_PARTICLES];
  float[]   dposx2 = new float[NUM_OF_PARTICLES];
  float[]   dposx3 = new float[NUM_OF_PARTICLES];
  float[]   dposx4 = new float[NUM_OF_PARTICLES];
  float[] posyprev = new float[NUM_OF_PARTICLES];
  float[] posywork = new float[NUM_OF_PARTICLES];
  float[]   dposy1 = new float[NUM_OF_PARTICLES];
  float[]   dposy2 = new float[NUM_OF_PARTICLES];
  float[]   dposy3 = new float[NUM_OF_PARTICLES];
  float[]   dposy4 = new float[NUM_OF_PARTICLES];
  float[] velxprev = new float[NUM_OF_PARTICLES];
  float[] velxwork = new float[NUM_OF_PARTICLES];
  float[]   dvelx1 = new float[NUM_OF_PARTICLES];
  float[]   dvelx2 = new float[NUM_OF_PARTICLES];
  float[]   dvelx3 = new float[NUM_OF_PARTICLES];
  float[]   dvelx4 = new float[NUM_OF_PARTICLES];
  float[] velyprev = new float[NUM_OF_PARTICLES];
  float[] velywork = new float[NUM_OF_PARTICLES];
  float[]   dvely1 = new float[NUM_OF_PARTICLES];
  float[]   dvely2 = new float[NUM_OF_PARTICLES];
  float[]   dvely3 = new float[NUM_OF_PARTICLES];
  float[]   dvely4 = new float[NUM_OF_PARTICLES];

  for (int j=0; j<NUM_OF_PARTICLES; j++) {
    posxprev[j] = particlePosX[j];
    posyprev[j] = particlePosY[j];
    velxprev[j] = particleVelX[j];
    velyprev[j] = particleVelY[j];
  }

  //step 1 
  equationOfMotion(posxprev,
                   posyprev,
                   velxprev,
                   velyprev,
                     dposx1,
                     dposy1,
                     dvelx1,
                     dvely1,
                         dt);
  rungeKutta4Advance(NUM_OF_PARTICLES,
                     posxwork,
                     posywork,
                     velxwork,
                     velywork,
                     posxprev,
                     posyprev,
                     velxprev,
                     velyprev,
                       dposx1,
                       dposy1,
                       dvelx1,
                       dvely1,
                          0.5);                        
  boundaryCondition( time, posxwork, posywork);

  time += 0.5*dt;

  //step 2
  equationOfMotion(posxwork,
                   posywork,
                   velxwork,
                   velywork,
                     dposx2,
                     dposy2,
                     dvelx2,
                     dvely2,
                         dt);
  rungeKutta4Advance(NUM_OF_PARTICLES,
                     posxwork,
                     posywork,
                     velxwork,
                     velywork,
                     posxprev,
                     posyprev,
                     velxprev,
                     velyprev,
                       dposx2,
                       dposy2,
                       dvelx2,
                       dvely2,
                          0.5);
  boundaryCondition( time, posxwork, posywork);
                          
  //step 3
  equationOfMotion(posxwork,
                   posywork,
                   velxwork,
                   velywork,
                     dposx3,
                     dposy3,
                     dvelx3,
                     dvely3,
                         dt);
  rungeKutta4Advance(NUM_OF_PARTICLES,
                     posxwork,
                     posywork,
                     velxwork,
                     velywork,
                     posxprev,
                     posyprev,
                     velxprev,
                     velyprev,
                       dposx3,
                       dposy3,
                       dvelx3,
                       dvely3,
                          1.0);
  boundaryCondition( time, posxwork, posywork);

  time += 0.5*dt;

  //step 4
  equationOfMotion(posxwork,
                   posywork,
                   velxwork,
                   velywork,
                     dposx4,
                     dposy4,
                     dvelx4,
                     dvely4,
                         dt);
  
  //the result
  for (int j=1; j<NUM_OF_PARTICLES-1; j++) { 
    posxwork[j] = posxprev[j] + (
                           ONE_SIXTH*dposx1[j]
                         + ONE_THIRD*dposx2[j]
                         + ONE_THIRD*dposx3[j]
                         + ONE_SIXTH*dposx4[j] 
                         );
    posywork[j] = posyprev[j] + (
                           ONE_SIXTH*dposy1[j]
                         + ONE_THIRD*dposy2[j]
                         + ONE_THIRD*dposy3[j]
                         + ONE_SIXTH*dposy4[j] 
                         );
    velxwork[j] = velxprev[j] + (
                           ONE_SIXTH*dvelx1[j]
                         + ONE_THIRD*dvelx2[j]
                         + ONE_THIRD*dvelx3[j]
                         + ONE_SIXTH*dvelx4[j] 
                         );
    velywork[j] = velyprev[j] + (
                           ONE_SIXTH*dvely1[j]
                         + ONE_THIRD*dvely2[j]
                         + ONE_THIRD*dvely3[j]
                         + ONE_SIXTH*dvely4[j] 
                         );
  }
  
  boundaryCondition( time, posxwork, posywork);
  
  for (int j=0; j<NUM_OF_PARTICLES; j++) {
    particlePosX[j] = posxwork[j];
    particlePosY[j] = posywork[j];
    particleVelX[j] = velxwork[j];
    particleVelY[j] = velywork[j];
  }

}
