package options.submenus;

import options.Option;

class GameplaySubState extends OptionsSubState {
    public function new() {
        super();

        var option:Option = new Option("Song Speed", 
            "Adjust the scroll speed of the notes.", 
            OptionType.Integer(1, 10, 1), 
            SaveData.settings.songSpeed
        );
        addOption(option);

        var option:Option = new Option("Downscroll", 
            "Makes the arrows go down instead of up.", 
            OptionType.Toggle, 
            SaveData.settings.downScroll
        );
        addOption(option);

        var option:Option = new Option("Hitsound Volume", 
            "Changes the volume of the hitsound", 
            OptionType.Decimal(0.1, 1, 0.1), 
            SaveData.settings.hitSoundVolume
        );
        option.showPercentage = true;
        addOption(option);

        var option:Option = new Option("Botplay", 
            "If enabled, the game plays for you.", 
            OptionType.Toggle, 
            SaveData.settings.botPlay
        );
        addOption(option);

        var option:Option = new Option("Anti-mash", 
            "If enabled, you will get a miss for pressing keys when no notes are present.", 
            OptionType.Toggle, 
            SaveData.settings.antiMash
        );
        addOption(option);
    }
}