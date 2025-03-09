class Portal extends Actor
        placeable;
 
 
var MaterialInstanceConstant PortalMaterialInstance;
var StaticMeshComponent StaticMesh;
var StaticMeshComponent traceMesh;
var() bool Enabled;
var() SceneCapturePortalComponent pCaptureComponent;
//var private SceneCaptureCubeMapComponent pCubeComponent;
//var private TextureRenderTargetCube cubeTarget;
//var private TextureRenderTarget texTarget;
var public TextureRenderTarget2D textureTarget;
 
var public array<Actor> ignoreArray;
var() repnotify Portal MyTarget;
var bool bteleportedTo;
var float lastDeltaTime;
 
replication
{
        if (bNetDirty)
                MyTarget,textureTarget,pCaptureComponent;
}
simulated event ReplicatedEvent(name VarName)
{
        if (VarName == 'MyTarget')
        {
                setClientTarget(MyTarget);
        }
 
}
function refresh()
{
}
 
static function Matrix transpose(Matrix m){
        local Matrix ret;
        ret.XPlane.X = m.XPlane.X;
        ret.XPlane.Y = m.YPlane.X;
        ret.XPlane.Z = m.ZPlane.X;
        ret.YPlane.X = m.XPlane.Y;
        ret.YPlane.Y = m.YPlane.Y;
        ret.YPlane.Z = m.ZPlane.Y;
        ret.ZPlane.X = m.XPlane.Z;
        ret.ZPlane.Y = m.YPlane.Z;
        ret.ZPlane.Z = m.ZPlane.Z;
        return ret;
}
 
 
static function Vector multiplyVectorWithMatrix(Vector v,Matrix m){
        local Vector ret;
        ret.X = v.X*m.XPlane.X+v.Y*m.YPlane.X+v.Z*m.ZPlane.X;
        ret.Y = v.X*m.XPlane.Y+v.Y*m.YPlane.Y+v.Z*m.ZPlane.Y;
        ret.Z = v.X*m.XPlane.Z+v.Y*m.YPlane.Z+v.Z*m.ZPlane.Z;
        return ret;
}
static function rotateVecByNormals(out vector vec, Vector entryNormal, vector exitNormal){
        local Vector X,Y,Z;
        local Matrix sourceAxis, destAxis;
        GetAxes(Rotator(entryNormal),X,Y,Z);
        sourceAxis.XPlane = X;
        sourceAxis.YPlane = Y;
        sourceAxis.ZPlane = Z;
        sourceAxis = transpose(sourceAxis);
        GetAxes(Rotator(exitNormal),X,Y,Z);
        destAxis.XPlane = X;
        destAxis.YPlane = Y;
        destAxis.ZPlane = Z;
        PortalRotate( vec, sourceAxis, destAxis, false, false );
}
static function Rotator rfa(Vector X,vector Y,vector Z){
        local Matrix mat;
        mat.XPlane = X;
        mat.YPlane = Y;
        mat.ZPlane = Z;
        return MatrixGetRotator(mat);
}
static function PortalRotate( out Vector vec, Matrix sourceTranspose, Matrix dest, optional bool flippX, optional bool flippY ) {
        local Vector outVec;
        outVec = vec;
        outVec = multiplyVectorWithMatrix(outVec,sourceTranspose);
        if ( flippX ) {
                outVec.X *= -1;
        }
        if( flippY ) {
                outVec.Y *= -1;
        }
        outVec = multiplyVectorWithMatrix(outVec,dest);
        vec = outVec;
}
 
public function Vector transformHitLocation(vector HitLocation,optional bool isProjectile){
        local Matrix sourceAxis,destAxis;
        local Vector X,Y,Z;
        local Vector d;
        local Vector locationOffset;
        local float bleh;
       
        locationOffset = HitLocation - self.Location;
        d = HitLocation;
        if(MyTarget != none){
                d = locationOffset;
                GetAxes(self.Rotation,X,Y,Z);
                sourceAxis.XPlane = X;
                sourceAxis.YPlane = Y;
                sourceAxis.ZPlane = Z;
                sourceAxis = transpose(sourceAxis);
                GetAxes(MyTarget.Rotation,X,Y,Z);
                destAxis.XPlane = X;
                destAxis.YPlane = Y;
                destAxis.ZPlane = Z;
                PortalRotate( d, sourceAxis, destAxis, false, true );
                d += MyTarget.Location;
                if(isProjectile){
                        bleh = ((Vector(MyTarget.Rotation) dot d)-(Vector(MyTarget.Rotation) dot MyTarget.Location));
                        d -= Vector(MyTarget.Rotation)*2*bleh;
                }
        }
        return d;
}
public function Rotator TransformDir(Rotator Dir){
        return Rotator(TransformVectorDir(Vector(Dir)));
}
private function Vector vfp(Plane p){
        local Vector res;
        res.X = p.X;
        res.Y = p.Y;
        res.Z = p.Z;
        return res;
}
public function Rotator TransformRotation(Rotator Dir){
        local Matrix sourceAxis,destAxis,rotAxis;
        local Vector X,Y,Z;
        if(MyTarget != none){
                GetAxes(self.Rotation,X,Y,Z);
                sourceAxis.XPlane = X;
                sourceAxis.YPlane = Y;
                sourceAxis.ZPlane = Z;
                sourceAxis = transpose(sourceAxis);
                GetAxes(MyTarget.Rotation,X,Y,Z);
                destAxis.XPlane = X;
                destAxis.YPlane = Y;
                destAxis.ZPlane = Z;
                rotAxis = MakeRotationMatrix(Dir);
                X = vfp(rotAxis.XPlane);
                Y = vfp(rotAxis.YPlane);
                Z = vfp(rotAxis.ZPlane);
                PortalRotate( X, sourceAxis, destAxis, true, true );
                PortalRotate( Y, sourceAxis, destAxis, true, true );
                PortalRotate( Z, sourceAxis, destAxis, true, true );
                rotAxis.XPlane = X;
                rotAxis.YPlane = Y;
                rotAxis.ZPlane = Z;
                return MatrixGetRotator(rotAxis);
        }
        return Dir;
}
public function Vector TransformVectorDir(vector Dir){
        local Matrix sourceAxis,destAxis;
        local Vector X,Y,Z;
        local Vector d;
        d = Dir;
        if(MyTarget != none){
                GetAxes(self.Rotation,X,Y,Z);
                sourceAxis.XPlane = X;
                sourceAxis.YPlane = Y;
                sourceAxis.ZPlane = Z;
                sourceAxis = transpose(sourceAxis);
                GetAxes(MyTarget.Rotation,X,Y,Z);
                destAxis.XPlane = X;
                destAxis.YPlane = Y;
                destAxis.ZPlane = Z;
                PortalRotate( d, sourceAxis, destAxis, true, true );
        }
        return d;
}
reliable server function unTouched(Actor Other){
}
simulated event unTouch(Actor Other){
        unTouched(Other);
}
reliable server function touched(Actor A,Vector HitNormal){
        if(Enabled){
                if(ignoreArray.Find(A) == INDEX_NONE || A != MyTarget){
                        if(!IsZero(A.Velocity) && (A.Velocity dot Vector(Rotation))<0){
                               
                                `log("Touched"@A);
                                if(A.IsA('Projectile')){
                                        tele(A,,true);
                                }
                                else if(distanceFromPlane(A.Location)<=0){
                                        tele(A);
                                }
                               
                        }
                }
        }
}
simulated event Touch( Actor A, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal ){
        touched(A,HitNormal);
}
reliable server function updatePos(Vector loc, Rotator rot){
        SetLocation(loc);
        SetRotation(rot);
        ForceNetRelevant();
        bUpdateSimulatedPosition = true;
}
 
reliable client function tele(Actor A,optional Vector aLoc,optional bool isProjectile){
        local Vector finalLoc;
        local Rotator finalRot;
        if(ignoreArray.Find(A) == INDEX_NONE){
                MyTarget.ignoreArray.AddItem(A);
                if(IsZero(aLoc))
                        aLoc = A.Location;
                finalLoc = transformHitLocation(aLoc,isProjectile);
                finalRot = TransformRotation(A.Rotation);
				
                if(Pawn(A) != none && PlayerController(Pawn(A).Controller) != none){
                        PlayerController(Pawn(A).Controller).ClientSetLocation(finalLoc,((TransformRotation(Pawn(A).Controller.Rotation))));
                        
                }
                A.SetRotation(finalRot);
                A.Velocity=TransformVectorDir(A.Velocity);
                A.SetLocation(finalLoc);
                A.Acceleration = TransformVectorDir(A.Acceleration);
                A.ForceNetRelevant();
                A.bUpdateSimulatedPosition = true;
        }
}
function float distanceFromPlane(Vector P){
        return (Vector(Rotation) dot P)-(Vector(Rotation) dot Location);
}
 
function Tick(float deltaTime){
        local Actor A;
        lastDeltaTime = deltaTime;
        if(Enabled){
               
                if(MyTarget == none){
                        pCaptureComponent.SetCaptureParameters(textureTarget,,self);
                }
                else if(pCaptureComponent.TextureTarget != textureTarget){
                        pCaptureComponent.SetCaptureParameters(textureTarget,,MyTarget);
                }
       
				/*
                ForEach VisibleCollidingActors(class'Actor',A,512,Location){
                        if(KActor(A)!=none){
                                KActor(A).bNoEncroachCheck=false;
                        }
                }
				*/
               
                ForEach TouchingActors(class'Actor', A){
                        if(MyTarget!=A||ignoreArray.Find(A) == INDEX_NONE){
                                if(!IsZero(A.Velocity) && (distanceFromPlane(A.Location)) >= 0 && (distanceFromPlane(A.Location+(A.Velocity*deltaTime*2))) < 0){
                                       
                                        tele(A,A.Location+(A.Velocity*deltaTime));
                                }
                        }
                }
               
                ignoreArray.Length=0;
        }
}
 
 
event Bump(Actor Other,PrimitiveComponent OtherComp,Vector HitNormal){
}
 
 
reliable server function setTarget(Portal targ)
{
        MyTarget = targ;
        pCaptureComponent.SetCaptureParameters(textureTarget,,targ);
        setClientTarget(targ);
 
}
reliable client function setClientTarget(Portal targ){
        MyTarget = targ;
        pCaptureComponent.SetCaptureParameters(textureTarget,,targ);
}
 
simulated function PostBeginPlay()
{
       
        `log( self @ GetFuncName() );
        if(Enabled){
        textureTarget = class'TextureRenderTarget2D'.static.Create( 1024,1024,PF_FloatRGB);
        //texTarget = new(self) class'TextureRenderTargetCube'; 
        pCaptureComponent.SetCaptureParameters(textureTarget,,self);
        //AttachComponent(pCaptureComponent);
 
        PortalMaterialInstance = new(self) class'MaterialInstanceConstant';
        PortalMaterialInstance.SetParent(Material'Portals.PortalMat');
        PortalMaterialInstance.SetTextureParameterValue('Param', textureTarget);
		StaticMesh.SetMaterial(0,PortalMaterialInstance);
        if(MyTarget == none)
                MyTarget=self;
 
                pCaptureComponent.SetCaptureParameters(textureTarget,,MyTarget);
        }
        else{
                SetHidden(true);
        }
}
event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
                                const out CollisionImpactData RigidCollisionData, int ContactIndex ){
        `log(RigidCollisionData.ContactInfos.Length);
}
simulated function bool StopsProjectile(Projectile P)
{
        return false;
}
defaultproperties
{
        bHidden=false
        Enabled = true
        bEdShouldSnap=true
		//Components.Add( TextureRenderTarget0 )


        Begin Object Class=SceneCapturePortalComponent Name=SceneCapturePortalComponent0
            ViewMode = SceneCapView_LitNoShadows
        End Object
        pCaptureComponent=SceneCapturePortalComponent0
        Components.Add( SceneCapturePortalComponent0 )
       
        Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
            HiddenGame=true
            CastShadow=false
            CollideActors=true
            bAcceptsLights=false
            bAcceptsDecals=false
            bAcceptsDecalsDuringGameplay=false
            bAcceptsStaticDecals=false
            bAcceptsDynamicLights=false
            bAcceptsDynamicDominantLightShadows=false
            bCastDynamicShadow=false
            StaticMesh=StaticMesh'EditorMeshes.TexPropPlane'
            RBChannel=RBCC_Default
            RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
            BlockRigidBody=true
            bNotifyRigidBodyCollision=true
            ScriptRigidBodyCollisionThreshold=0.01
        End Object
        Components.Add(StaticMeshComponent0)
 
       
        Begin Object Class=StaticMeshComponent Name=StaticMeshComponent1
            HiddenGame=false
            CastShadow=false
            CollideActors=true
            bAcceptsLights=false
            bAcceptsDecals=false
            bAcceptsDecalsDuringGameplay=false
            bAcceptsStaticDecals=false
            bAcceptsDynamicLights=false
            bAcceptsDynamicDominantLightShadows=false
            bCastDynamicShadow=false
            StaticMesh=StaticMesh'EditorMeshes.TexPropPlane'
            RBChannel=RBCC_Default
            RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
            BlockRigidBody=true
            bNotifyRigidBodyCollision=true
            ScriptRigidBodyCollisionThreshold=0.01
            Translation=(X=-15.0,Y=0.0,Z=0.0)
        End Object
        Components.Add(StaticMeshComponent1)
        StaticMesh=StaticMeshComponent1
        CollisionComponent=StaticMeshComponent1
 
        bCollideActors=true
        bProjTarget=true
        bStatic=false
        bNoEncroachCheck=false
        bIgnoreEncroachers=false
        CollisionType = COLLIDE_TouchAll
        RemoteRole=ROLE_SimulatedProxy
        bNoDelete=false
        NetUpdateFrequency = 10
        bAlwaysRelevant = true
}