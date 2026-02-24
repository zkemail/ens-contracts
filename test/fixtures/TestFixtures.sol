// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "../../src/verifiers/ProveAndClaimCommandVerifier.sol";
import { LinkEmailCommand } from "../../src/verifiers/LinkEmailCommandVerifier.sol";
import { EmailAuthProof, PublicInputs } from "../../src/verifiers/EmailAuthVerifier.sol";
import { TextRecord } from "../../src/entrypoints/LinkTextRecordEntrypoint.sol";

/**
 * @title TestFixtures
 * @notice Provides test data and fixtures for ZK Email ENS registrar testing
 * @dev This library contains pre-computed test data including valid ProveAndClaimCommand structs
 *      and their corresponding expected public signals for verification testing.
 *
 *      The test data includes:
 *      - A complete ProveAndClaimCommand with real cryptographic proof components
 *      - The expected 60-element public signals array for proof verification
 *      - ASCII text representations encoded as BN128 field elements
 *      - Valid RSA public key components for DKIM verification
 *
 *      This data is used to test the verifier's ability to correctly process and verify
 *      email-based ENS claims without requiring live email generation during testing.
 */
library TestFixtures {
    /**
     * @notice Provides a complete test case for ENS claim verification
     * @return command A fully populated ProveAndClaimCommand struct with test data
     * @return expectedPublicInputs The expected 60-element public inputs fields array for verification
     * @dev This function returns test data representing a claim for "thezdev1[at]gmail.com" to be
     *      mapped to ENS name ownership by address 0xafBD210c60dD651892a61804A989eEF7bD63CBA0.
     *
     *      The returned data includes:
     *      - Domain: "gmail.com"
     *      - Email: "thezdev1[at]gmail.com"
     *      - Owner: 0xafBD210c60dD651892a61804A989eEF7bD63CBA0
     *      - Valid ZK proof components (pA, pB, pC) for Groth16 verification
     *      - DKIM signer hash for Gmail's public key
     *      - Nullifier to prevent replay attacks
     *      - RSA public key components encoded in miscellaneousData
     *
     *      The expectedPublicInputs array contains field elements representing:
     *      1. Domain name "gmail.com" (packed into 9 fields)
     *      2. DKIM signer hash (1 field)
     *      3. Email nullifier (1 field)
     *      4. Timestamp (1 field, set to 0)
     *      5. Command text "Claim ENS name for address 0x... with resolver resolver.eth" (packed into 20 fields)
     *      6. Account salt (1 field)
     *      7. Code embedded flag (1 field, set to 0)
     *      8. RSA public key modulus (17 fields)
     *      9. Email address "thezdev1[at]gmail.com" (packed into 9 fields)
     *
     *      ASCII text conversion note:
     *      Field elements represent ASCII text in reversed byte order. To verify conversion:
     *      ```python
     *      def field_to_ascii(field_value):
     *          hex_str = hex(field_value)[2:]
     *          if len(hex_str) % 2:
     *              hex_str = '0' + hex_str
     *          bytes_data = bytes.fromhex(hex_str)
     *          return bytes_data.decode('ascii').rstrip('\x00')[::-1]  # reverse
     *      ```
     *
     *      Example: field_to_ascii(2_018_721_414_038_404_820_327) returns "gmail.com"
     */
    function claimEnsCommand()
        internal
        pure
        returns (ProveAndClaimCommand memory command, bytes32[] memory expectedPublicInputs)
    {
        // RSA public key modulus decomposed into 17 field elements for ZK circuit compatibility
        // This represents Gmail's DKIM public key used for signature verification
        uint256[17] memory pubkey = [
            uint256(2_107_195_391_459_410_975_264_579_855_291_297_887),
            uint256(2_562_632_063_603_354_817_278_035_230_349_645_235),
            uint256(1_868_388_447_387_859_563_289_339_873_373_526_818),
            uint256(2_159_353_473_203_648_408_714_805_618_210_333_973),
            uint256(351_789_365_378_952_303_483_249_084_740_952_389),
            uint256(659_717_315_519_250_910_761_248_850_885_776_286),
            uint256(1_321_773_785_542_335_225_811_636_767_147_612_036),
            uint256(258_646_249_156_909_342_262_859_240_016_844_424),
            uint256(644_872_192_691_135_519_287_736_182_201_377_504),
            uint256(174_898_460_680_981_733_302_111_356_557_122_107),
            uint256(1_068_744_134_187_917_319_695_255_728_151_595_132),
            uint256(1_870_792_114_609_696_396_265_442_109_963_534_232),
            uint256(8_288_818_605_536_063_568_933_922_407_756_344),
            uint256(1_446_710_439_657_393_605_686_016_190_803_199_177),
            uint256(2_256_068_140_678_002_554_491_951_090_436_701_670),
            uint256(518_946_826_903_468_667_178_458_656_376_730_744),
            uint256(3_222_036_726_675_473_160_989_497_427_257_757)
        ];

        // Groth16 proof component A (from proof.json)
        uint256[2] memory pA = [
            20_943_545_957_642_006_692_494_364_844_898_901_601_205_454_077_861_927_262_950_680_655_390_287_383_341,
            17_860_092_024_149_067_532_564_703_509_121_210_613_423_405_372_260_424_068_184_938_094_570_052_356_092
        ];

        // Groth16 proof component B (from proof.json)
        uint256[2][2] memory pB = [
            [
                10_132_275_804_483_032_942_054_592_886_727_959_198_541_015_472_658_522_827_170_172_312_740_146_919_650,
                15_983_896_597_582_449_765_542_066_723_775_104_097_572_338_467_060_537_481_227_026_660_188_775_176_192
            ],
            [
                11_050_849_750_802_713_466_110_201_500_246_278_548_989_477_859_118_124_906_412_314_644_384_529_997_332,
                2_953_258_356_972_585_703_899_454_050_759_760_890_936_111_329_989_475_577_005_243_192_320_614_772_978
            ]
        ];

        // Groth16 proof component C (from proof.json)
        uint256[2] memory pC = [
            14_717_306_353_995_492_554_024_937_717_066_417_128_247_022_860_569_068_798_621_971_300_922_743_404_189,
            19_957_238_458_701_593_508_603_242_355_834_583_845_375_631_379_272_997_898_684_266_101_439_550_379_577
        ];

        string[] memory emailParts = new string[](2);
        emailParts[0] = "thezdev1$gmail";
        emailParts[1] = "com";

        PublicInputs memory fields = PublicInputs({
            domainName: "gmail.com",
            publicKeyHash: hex"0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788",
            emailNullifier: hex"04DE80D5184510B6208D6456C091FF3E177F28C2DE49B7B7618B6EF147B817EF",
            timestamp: 0,
            maskedCommand: "Claim ENS name for address 0xafBD210c60dD651892a61804A989eEF7bD63CBA0"
            " with resolver resolver.eth",
            accountSalt: hex"11DD2E9EDE9B5BA105A03650FF6B74F3D4F19E75DD64C53C8DC8F7AB82403912",
            isCodeExist: false,
            miscellaneousData: abi.encode(pubkey),
            emailAddress: "thezdev1@gmail.com"
        });

        EmailAuthProof memory emailAuthProof = EmailAuthProof({ publicInputs: fields, proof: abi.encode(pA, pB, pC) });

        // Complete ProveAndClaimCommand struct with test data for "thezdev1@gmail.com"
        command = ProveAndClaimCommand({
            emailParts: emailParts,
            resolver: "resolver.eth",
            owner: 0xafBD210c60dD651892a61804A989eEF7bD63CBA0,
            emailAuthProof: emailAuthProof
        });

        uint256[60] memory expectedPublicInputsFields = [
            2_018_721_414_038_404_820_327,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            6_632_353_713_085_157_925_504_008_443_078_919_716_322_386_156_160_602_218_536_961_028_046_468_237_192,
            2_202_380_611_270_802_977_810_424_243_055_429_330_904_378_876_663_812_534_622_621_703_884_867_377_135,
            0,
            180_891_110_264_973_503_160_226_225_538_030_206_223_858_091_522_603_795_023_666_265_748_100_181_059,
            173_532_502_901_810_909_445_165_194_544_006_900_992_761_359_126_983_071_590_425_318_149_531_518_018,
            82_064_499_489_411_320_061_695_384_032_176_580_663_311_076_544_288_210_199_978_613_071_800_383_044,
            6_845_541,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            8_080_113_390_678_316_609_048_973_094_352_283_823_282_558_465_605_593_816_562_416_100_021_989_554_450,
            0,
            2_107_195_391_459_410_975_264_579_855_291_297_887,
            2_562_632_063_603_354_817_278_035_230_349_645_235,
            1_868_388_447_387_859_563_289_339_873_373_526_818,
            2_159_353_473_203_648_408_714_805_618_210_333_973,
            351_789_365_378_952_303_483_249_084_740_952_389,
            659_717_315_519_250_910_761_248_850_885_776_286,
            1_321_773_785_542_335_225_811_636_767_147_612_036,
            258_646_249_156_909_342_262_859_240_016_844_424,
            644_872_192_691_135_519_287_736_182_201_377_504,
            174_898_460_680_981_733_302_111_356_557_122_107,
            1_068_744_134_187_917_319_695_255_728_151_595_132,
            1_870_792_114_609_696_396_265_442_109_963_534_232,
            8_288_818_605_536_063_568_933_922_407_756_344,
            1_446_710_439_657_393_605_686_016_190_803_199_177,
            2_256_068_140_678_002_554_491_951_090_436_701_670,
            518_946_826_903_468_667_178_458_656_376_730_744,
            3_222_036_726_675_473_160_989_497_427_257_757,
            9_533_142_343_906_178_599_764_761_089_706_585_145_829_492,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];

        expectedPublicInputs = new bytes32[](60);
        for (uint256 i = 0; i < 60; i++) {
            expectedPublicInputs[i] = bytes32(expectedPublicInputsFields[i]);
        }

        return (command, expectedPublicInputs);
    }

    function linkEmailCommand()
        internal
        pure
        returns (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs)
    {
        // RSA public key modulus decomposed into 17 field elements for ZK circuit compatibility
        // This represents Gmail's DKIM public key used for signature verification
        uint256[17] memory pubkey = [
            uint256(2_107_195_391_459_410_975_264_579_855_291_297_887),
            uint256(2_562_632_063_603_354_817_278_035_230_349_645_235),
            uint256(1_868_388_447_387_859_563_289_339_873_373_526_818),
            uint256(2_159_353_473_203_648_408_714_805_618_210_333_973),
            uint256(351_789_365_378_952_303_483_249_084_740_952_389),
            uint256(659_717_315_519_250_910_761_248_850_885_776_286),
            uint256(1_321_773_785_542_335_225_811_636_767_147_612_036),
            uint256(258_646_249_156_909_342_262_859_240_016_844_424),
            uint256(644_872_192_691_135_519_287_736_182_201_377_504),
            uint256(174_898_460_680_981_733_302_111_356_557_122_107),
            uint256(1_068_744_134_187_917_319_695_255_728_151_595_132),
            uint256(1_870_792_114_609_696_396_265_442_109_963_534_232),
            uint256(8_288_818_605_536_063_568_933_922_407_756_344),
            uint256(1_446_710_439_657_393_605_686_016_190_803_199_177),
            uint256(2_256_068_140_678_002_554_491_951_090_436_701_670),
            uint256(518_946_826_903_468_667_178_458_656_376_730_744),
            uint256(3_222_036_726_675_473_160_989_497_427_257_757)
        ];

        // Groth16 proof component A (from proof.json)
        // Groth16 proof component A (from proof.json)
        uint256[2] memory pA = [
            15_498_314_161_619_032_549_243_393_617_657_845_623_258_409_148_667_976_922_110_624_590_703_394_148_599,
            767_450_848_841_886_091_558_864_457_828_792_619_788_858_039_614_858_439_411_008_284_499_005_333_778
        ];

        // Groth16 proof component B (from proof.json)
        uint256[2][2] memory pB = [
            [
                14_338_799_160_467_194_874_706_035_887_803_806_223_098_120_213_132_782_013_003_648_399_353_896_116_987,
                19_907_225_661_377_940_806_196_720_057_576_218_896_543_170_472_958_519_594_216_140_867_979_854_064_427
            ],
            [
                523_845_405_481_733_000_535_644_163_421_613_108_480_598_166_982_275_738_551_120_677_984_412_216_763,
                4_997_634_597_845_375_898_960_513_717_152_195_127_778_820_391_450_900_632_072_647_523_966_335_542_408
            ]
        ];

        // Groth16 proof component C (from proof.json)
        uint256[2] memory pC = [
            15_385_936_630_496_637_031_308_281_077_303_858_479_213_936_830_164_050_060_698_917_457_824_042_084_067,
            10_974_005_087_812_821_683_028_658_419_683_444_499_946_740_682_173_447_741_820_877_084_771_970_288_594
        ];

        PublicInputs memory fields = PublicInputs({
            domainName: "gmail.com",
            publicKeyHash: hex"0EA9C777DC7110E5A9E89B13F0CFC540E3845BA120B2B6DC24024D61488D4788",
            emailNullifier: hex"0CEF36D2E53A61D038B0F46466F7C1E4E5D62636FC3ACAB471C8AC6A0558F705",
            timestamp: 0,
            maskedCommand: "Link my email to zkfriendly.eth",
            accountSalt: hex"11DD2E9EDE9B5BA105A03650FF6B74F3D4F19E75DD64C53C8DC8F7AB82403912",
            isCodeExist: false,
            miscellaneousData: abi.encode(pubkey),
            emailAddress: "thezdev1@gmail.com"
        });

        EmailAuthProof memory emailAuthProof = EmailAuthProof({ publicInputs: fields, proof: abi.encode(pA, pB, pC) });

        command = LinkEmailCommand({
            textRecord: TextRecord({
                platformName: "email",
                ensName: "zkfriendly.eth",
                value: "thezdev1@gmail.com",
                nullifier: hex"0CEF36D2E53A61D038B0F46466F7C1E4E5D62636FC3ACAB471C8AC6A0558F705"
            }),
            emailAuthProof: emailAuthProof
        });

        uint256[60] memory expectedPublicInputsFields = [
            2_018_721_414_038_404_820_327,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            6_632_353_713_085_157_925_504_008_443_078_919_716_322_386_156_160_602_218_536_961_028_046_468_237_192,
            5_850_409_011_513_289_095_527_448_599_311_977_678_666_774_279_259_222_181_536_778_241_498_689_369_861,
            0,
            184_555_425_162_109_167_229_080_696_008_655_757_906_148_516_663_968_797_901_501_065_554_486_520_140,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            8_080_113_390_678_316_609_048_973_094_352_283_823_282_558_465_605_593_816_562_416_100_021_989_554_450,
            0,
            2_107_195_391_459_410_975_264_579_855_291_297_887,
            2_562_632_063_603_354_817_278_035_230_349_645_235,
            1_868_388_447_387_859_563_289_339_873_373_526_818,
            2_159_353_473_203_648_408_714_805_618_210_333_973,
            351_789_365_378_952_303_483_249_084_740_952_389,
            659_717_315_519_250_910_761_248_850_885_776_286,
            1_321_773_785_542_335_225_811_636_767_147_612_036,
            258_646_249_156_909_342_262_859_240_016_844_424,
            644_872_192_691_135_519_287_736_182_201_377_504,
            174_898_460_680_981_733_302_111_356_557_122_107,
            1_068_744_134_187_917_319_695_255_728_151_595_132,
            1_870_792_114_609_696_396_265_442_109_963_534_232,
            8_288_818_605_536_063_568_933_922_407_756_344,
            1_446_710_439_657_393_605_686_016_190_803_199_177,
            2_256_068_140_678_002_554_491_951_090_436_701_670,
            518_946_826_903_468_667_178_458_656_376_730_744,
            3_222_036_726_675_473_160_989_497_427_257_757,
            9_533_142_343_906_178_599_764_761_089_706_585_145_829_492,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];

        expectedPublicInputs = new bytes32[](60);
        for (uint256 i = 0; i < 60; i++) {
            expectedPublicInputs[i] = bytes32(expectedPublicInputsFields[i]);
        }

        return (command, expectedPublicInputs);
    }
}
