//
//  SchemaFixtures.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation

// The files indent by four spaces, as cktool writes them.
// swiftlint:disable indentation_width

/// `.ckdb` files from Mistico's `Fixtures/`, kept here as text because the
/// test target has no resources.
internal enum SchemaFixtures {
  /// PROVISIONAL, hand-written: every construct in Apple's grammar
  /// (`Fixtures/Provisional/schema/everything.ckdb`).
  internal static let everything = """
    // Hand-written provisional fixture for SchemaKit (#50). Unverified: see README.md.
    -- Covers every construct in Apple's .ckdb grammar.
    DEFINE SCHEMA

        CREATE ROLE Moderator;
        CREATE ROLE "Support_Team";

        /* A record type with every primitive type,
           ENCRYPTED, NUMBER and lists. */
        RECORD TYPE Inventory (
            "___createTime"  TIMESTAMP SORTABLE,
            "___recordID"    REFERENCE QUERYABLE,
            attachment       ASSET,
            blob             BYTES,
            price            DOUBLE QUERYABLE SORTABLE,
            quantity         INT64 SORTABLE QUERYABLE,
            warehouse        LOCATION QUERYABLE,
            legacyCount      NUMBER,
            legacyWeight     NUMBER PREFERRED AS DOUBLE,
            legacyUnits      NUMBER PREFERRED AS INT64 QUERYABLE,
            supplier         REFERENCE QUERYABLE,
            title            STRING QUERYABLE SEARCHABLE SORTABLE,
            restockedAt      TIMESTAMP,
            secretNote       ENCRYPTED STRING,
            secretCode       ENCRYPTED BYTES,
            secretCost       ENCRYPTED DOUBLE,
            secretCount      ENCRYPTED INT64,
            secretPlace      ENCRYPTED LOCATION,
            secretDate       ENCRYPTED TIMESTAMP,
            tags             LIST<STRING> QUERYABLE,
            related          LIST<REFERENCE> QUERYABLE,
            photos           LIST<ASSET>,
            readings         LIST<DOUBLE>,
            counts           LIST<INT64>,
            stops            LIST<LOCATION>,
            times            LIST<TIMESTAMP>,
            chunks           LIST<BYTES>,
            secretTags       LIST<ENCRYPTED STRING>,
            "sortable"       STRING,
            GRANT READ, CREATE, WRITE TO Moderator,
            GRANT READ TO "Support_Team",
            GRANT WRITE TO "_creator",
            GRANT CREATE TO "_icloud",
            GRANT READ TO "_world"
        );

        record type "grant" (
            body string searchable,
            grant read to "_world"
        );

        RECORD TYPE Empty (
        );
    """

  /// PROVISIONAL, hand-written: `rating` has no data type (line 9, column 26)
  /// (`Fixtures/Provisional/schema/malformed.ckdb`).
  internal static let malformed = """
    // Hand-written provisional fixture for SchemaKit (#50). Unverified: see README.md.
    // One mistake: "rating" has no data type (line 9, column 26).
    DEFINE SCHEMA

        RECORD TYPE Player (
            "___recordID"    REFERENCE QUERYABLE,
            displayName      STRING QUERYABLE SORTABLE,
            handle           STRING QUERYABLE,
            rating           QUERYABLE SORTABLE,
            GRANT WRITE TO "_creator",
            GRANT READ TO "_world"
        );
    """

  /// Recorded: a real `cktool export-schema` of Mistico's scratch container
  /// (`Fixtures/Recorded/schema/export.ckdb`).
  internal static let recordedExport = """
    DEFINE SCHEMA

        RECORD TYPE Feedback (
            "___createTime" TIMESTAMP SORTABLE,
            "___createdBy"  REFERENCE QUERYABLE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP QUERYABLE SORTABLE,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE QUERYABLE,
            body            STRING SEARCHABLE,
            match           REFERENCE,
            player          REFERENCE QUERYABLE,
            rating          INT64 QUERYABLE SORTABLE,
            screenshot      ASSET,
            GRANT READ, WRITE TO "_creator",
            GRANT CREATE TO "_icloud"
        );

        RECORD TYPE Match (
            "___createTime" TIMESTAMP SORTABLE,
            "___createdBy"  REFERENCE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP QUERYABLE SORTABLE,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE QUERYABLE,
            durationSeconds INT64 QUERYABLE SORTABLE,
            players         LIST<REFERENCE> QUERYABLE,
            rematchOf       REFERENCE QUERYABLE,
            score           STRING,
            startedAt       TIMESTAMP QUERYABLE SORTABLE,
            venue           LOCATION QUERYABLE,
            winner          REFERENCE QUERYABLE,
            GRANT WRITE TO "_creator",
            GRANT CREATE TO "_icloud",
            GRANT READ TO "_world"
        );

        RECORD TYPE Player (
            "___createTime" TIMESTAMP SORTABLE,
            "___createdBy"  REFERENCE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP QUERYABLE SORTABLE,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE QUERYABLE,
            avatar          ASSET,
            country         STRING,
            displayName     STRING QUERYABLE SEARCHABLE SORTABLE,
            gamesPlayed     INT64 SORTABLE,
            handle          STRING QUERYABLE,
            lastSeen        TIMESTAMP QUERYABLE SORTABLE,
            rating          INT64 QUERYABLE SORTABLE,
            settings        STRING,
            GRANT WRITE TO "_creator",
            GRANT CREATE TO "_icloud",
            GRANT READ TO "_world"
        );

        RECORD TYPE Tournament (
            "___createTime" TIMESTAMP SORTABLE,
            "___createdBy"  REFERENCE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP QUERYABLE SORTABLE,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE QUERYABLE,
            bracket         BYTES,
            endsAt          TIMESTAMP QUERYABLE SORTABLE,
            entryFee        DOUBLE QUERYABLE SORTABLE,
            matches         LIST<REFERENCE> QUERYABLE,
            name            STRING QUERYABLE SEARCHABLE SORTABLE,
            startsAt        TIMESTAMP QUERYABLE SORTABLE,
            tags            LIST<STRING> QUERYABLE,
            GRANT WRITE TO "_creator",
            GRANT CREATE TO "_icloud",
            GRANT READ TO "_world"
        );

        RECORD TYPE Users (
            "___createTime" TIMESTAMP,
            "___createdBy"  REFERENCE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE QUERYABLE,
            roles           LIST<INT64>,
            GRANT WRITE TO "_creator",
            GRANT READ TO "_world"
        );
    """

  /// Recorded: the export cut off in the middle of a record type
  /// (`Fixtures/Recorded/schema/malformed.ckdb`).
  internal static let recordedMalformed = """
    DEFINE SCHEMA

        RECORD TYPE Feedback (
            "___createTime" TIMESTAMP SORTABLE,
            "___createdBy"  REFERENCE QUERYABLE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP QUERYABLE SORTABLE,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE QUERYABLE,
            body            STRING SEARCHABLE,
            match           REFERENCE,
            player          REFERENCE QUERYABLE,
    """
}
// swiftlint:enable indentation_width
