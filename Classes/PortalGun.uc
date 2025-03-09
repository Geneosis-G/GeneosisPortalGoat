/**
 * Copyright 1998-2010 Epic Games, Inc. All Rights Reserved.
 */
class PortalGun extends UDKWeapon
        HideDropDown;
 
 
var int portalSize;
var Portal portal[2];
var int hold;
var float distanceFromWall;
 
replication
{
        if (Role==ROLE_Authority && bNetDirty)
                hold;
}
 
simulated function PostBeginPlay()
{
        Super.PostbeginPlay();
}
 
reliable server function doPortal(byte i){
       
        local Vector HitLocation,HitNormal,EndShot,StartShot;
        local byte o;
        local int j/*,k*/;
        local int minBelow/*,minLeft,minRight,minUp*/;
        local Vector portalLocation,portalNormal;
        local Vector curOffset,X,LEFT,UP;
 
        StartShot=Location;
        EndShot=StartShot + (10000.0 * Normal(Vector(Rotation)));
 
        if(Trace(HitLocation,HitNormal,EndShot,StartShot)!=none){
                portalLocation = HitLocation;
                portalNormal = HitNormal;
                GetAxes(Rotator(HitNormal),X,LEFT,UP);
                minBelow = portalSize;
                for(j=0;j<portalSize;j++){
                        curOffset=portalNormal*distanceFromWall+LEFT*(portalSize/2)-UP*minBelow;
                        if(Trace(HitLocation,HitNormal,portalLocation+curOffset,portalLocation+portalNormal*distanceFromWall)!=none){
                                minBelow = VSize(HitLocation-portalLocation);
                        }
                }
                portalLocation = portalLocation+(portalSize-minBelow)*UP;
                if(i==0)
                        o=1;
                else
                        o=0;
                if(portal[i]==none)
				{
                    portal[i] = Spawn(class'Portal',,,portalLocation+HitNormal*distanceFromWall,Rotator(portalNormal));
				}
                else
				{
                    portal[i].updatePos(portalLocation+portalNormal*distanceFromWall,Rotator(portalNormal));
                }
				WorldInfo.Game.Broadcast(self, portal[i] $ "(" $ portal[i].Location $ ")");
                if(portal[o]!=none)
				{
                        portal[i].setTarget(portal[o]);
                        portal[o].setTarget(portal[i]);
                }
        }
}
simulated function StartFire(byte i)
{
        hold=i;
        doPortal(i);
        Super.StartFire( i );
}
 
simulated function StopFire(byte FireModeNum)
{
        hold=-1;
        Super.StopFire( FireModeNum );
}
 
simulated function bool DoOverridePrevWeapon()
{
        return false;
}
 
simulated function bool DoOverrideNextWeapon()
{
        return false;
}
 
simulated function Tick( float DeltaTime )
{
        if(Pawn(Owner) == none || Pawn(Owner).Health<=0){
                `log("amg dead");
                portal[0].Destroy();
                portal[1].Destroy();
        }
 
        if(hold!=-1){
                doPortal(hold);
        }
}
 
/**
 * Consumes some of the ammo
 */
function ConsumeAmmo( byte FireModeNum )
{
        // dont consume ammo
}
 
defaultproperties
{ 
	distanceFromWall=75
	WeaponColor=(R=255,G=128,B=128,A=255)
	FireInterval(0)=+1.0
	FireInterval(1)=+1.0
	PlayerViewOffset=(X=0.0,Y=7.0,Z=-9.0)

	Begin Object class=AnimNodeSequence Name=MeshSequenceA
	End Object

	WeaponFireTypes(0)=EWFT_Custom
	WeaponFireTypes(1)=EWFT_Projectile

	FireOffset=(X=16,Y=10)

	AIRating=+0.75
	CurrentRating=+0.75
	bInstantHit=false
	bSplashJump=false
	bRecommendSplashDamage=false
	bSniping=false
	ShouldFireOnRelease(0)=0
	ShouldFireOnRelease(1)=0
	bCanThrow=false

	InventoryGroup=666
	GroupWeight=0.5

	AmmoCount=5
	LockerAmmoCount=5
	MaxAmmoCount=5

	bExportMenuData=false

	portalSize=196;
	hold = -1;
}