class PortalGoat extends GGMutator;

var instanced array< PortalGoatComponent > mPortalGoatComponents;
var array< GGGoat > mGoatsUsingPortals;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked()
{
	return True;
}

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local GGLocalPlayer locPlayer;
	local PortalGoatComponent PortalComp;

	super.ModifyPlayer( other );
	
	goat = GGGoat( other );

	if( goat != none && IsValidForPlayer( goat ) )
	{
		locPlayer =  GGLocalPlayer( PlayerController( goat.Controller ).Player );
		PortalComp=mPortalGoatComponents[ locPlayer.mPlayerSlot ];
		PortalComp.AttachToPlayer( goat, self );
		mGoatsUsingPortals[ locPlayer.mPlayerSlot ] = goat;
	}
}

DefaultProperties
{
	Begin Object class=PortalGoatComponent Name=PortalGoat1
	End Object
	mPortalGoatComponents.Add(PortalGoat1)

	Begin Object class=PortalGoatComponent Name=PortalGoat2
	End Object
	mPortalGoatComponents.Add(PortalGoat2)

	Begin Object class=PortalGoatComponent Name=PortalGoat3
	End Object
	mPortalGoatComponents.Add(PortalGoat3)

	Begin Object class=PortalGoatComponent Name=PortalGoat4
	End Object
	mPortalGoatComponents.Add(PortalGoat4)
}