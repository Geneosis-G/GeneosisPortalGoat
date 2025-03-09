class PortalGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;
var PortalGun myPortalGun;
var byte blue;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	if(!mIsInitialized)
	{
		gMe=goat;
		myMut=owningMutator;
	}
	
	super.AttachToPlayer(goat, owningMutator);
}

/**
 * Setup mutator component.
 */
function InitMutatorComponent()
{
	super.InitMutatorComponent();
	
	if(gMe != none)
	{
		myPortalGun=gMe.Spawn(class'PortalGun',,, gMe.Location+vect(0, 0, 50),,, true);
		myPortalGun.SetBase(gMe,, gMe.mesh, 'Demonic');

		GGPlayerInput( PlayerController( gMe.Controller ).PlayerInput ).RegisterKeyDownListener( KeyDown );
	}
}

function KeyDown( name newKey )
{
	if(newKey == 'X' || newKey == 'XboxTypeS_LeftShoulder')
	{
		blue=1-blue;
		myPortalGun.doPortal(blue);
	}
}

defaultproperties
{
	
}