Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$outDir = Join-Path $root "project_docs\diagrams"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Color($hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function New-Canvas {
    param([string]$Title)
    $bmp = New-Object System.Drawing.Bitmap 1600, 900
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.Clear([System.Drawing.Color]::White)

    $titleFont = New-Object System.Drawing.Font "Segoe UI", 30, ([System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush (Color "#173f8a")
    $g.DrawString($Title, $titleFont, $titleBrush, 60, 35)
    $pen = New-Object System.Drawing.Pen (Color "#d7dde8"), 2
    $g.DrawLine($pen, 60, 92, 1540, 92)
    $pen.Dispose()
    $titleBrush.Dispose()
    $titleFont.Dispose()
    return @($bmp, $g)
}

function Draw-Box {
    param(
        [System.Drawing.Graphics]$G,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [string]$Text,
        [string]$Fill = "#f5f7fb",
        [string]$Border = "#173f8a",
        [int]$FontSize = 17
    )

    $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
    $textRect = New-Object System.Drawing.RectangleF ([float]$X), ([float]$Y), ([float]$W), ([float]$H)
    $brush = New-Object System.Drawing.SolidBrush (Color $Fill)
    $pen = New-Object System.Drawing.Pen (Color $Border), 3
    $G.FillRectangle($brush, $rect)
    $G.DrawRectangle($pen, $rect)

    $font = New-Object System.Drawing.Font "Segoe UI", $FontSize, ([System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush (Color "#1f2937")
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $G.DrawString($Text, $font, $textBrush, $textRect, $format)

    $format.Dispose()
    $textBrush.Dispose()
    $font.Dispose()
    $pen.Dispose()
    $brush.Dispose()
}

function Draw-Arrow {
    param(
        [System.Drawing.Graphics]$G,
        [int]$X1,
        [int]$Y1,
        [int]$X2,
        [int]$Y2,
        [string]$Color = "#173f8a"
    )

    $pen = New-Object System.Drawing.Pen (Color $Color), 4
    $cap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap 7, 7
    $pen.CustomEndCap = $cap
    $G.DrawLine($pen, $X1, $Y1, $X2, $Y2)
    $cap.Dispose()
    $pen.Dispose()
}

function Draw-Line {
    param(
        [System.Drawing.Graphics]$G,
        [int]$X1,
        [int]$Y1,
        [int]$X2,
        [int]$Y2,
        [string]$Color = "#6b7280"
    )

    $pen = New-Object System.Drawing.Pen (Color $Color), 3
    $G.DrawLine($pen, $X1, $Y1, $X2, $Y2)
    $pen.Dispose()
}

function Draw-Oval {
    param(
        [System.Drawing.Graphics]$G,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [string]$Text,
        [string]$Fill = "#ffffff",
        [string]$Border = "#173f8a",
        [int]$FontSize = 13
    )

    $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
    $textRect = New-Object System.Drawing.RectangleF ([float]$X), ([float]$Y), ([float]$W), ([float]$H)
    $brush = New-Object System.Drawing.SolidBrush (Color $Fill)
    $pen = New-Object System.Drawing.Pen (Color $Border), 3
    $G.FillEllipse($brush, $rect)
    $G.DrawEllipse($pen, $rect)

    $font = New-Object System.Drawing.Font "Segoe UI", $FontSize, ([System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush (Color "#1f2937")
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $G.DrawString($Text, $font, $textBrush, $textRect, $format)

    $format.Dispose()
    $textBrush.Dispose()
    $font.Dispose()
    $pen.Dispose()
    $brush.Dispose()
}

function Draw-Boundary {
    param(
        [System.Drawing.Graphics]$G,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [string]$Text
    )

    $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
    $pen = New-Object System.Drawing.Pen (Color "#173f8a"), 3
    $G.DrawRectangle($pen, $rect)

    $font = New-Object System.Drawing.Font "Segoe UI", 19, ([System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush (Color "#173f8a")
    $G.DrawString($Text, $font, $textBrush, ($X + 25), ($Y + 18))

    $textBrush.Dispose()
    $font.Dispose()
    $pen.Dispose()
}

function Save-Diagram {
    param([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Graphics]$Graphics, [string]$FileName)
    $path = Join-Path $outDir $FileName
    $Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Graphics.Dispose()
    $Bitmap.Dispose()
    Write-Host $path
}

function New-ExistingArchitecture {
    $items = New-Canvas "Architecture of the Existing System"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 60 385 230 120 "Student /`nCandidate" "#eaf2ff" "#173f8a" 18
    $sources = @(
        @(430, 150, "University`nwebsite"),
        @(780, 150, "Student`nportal"),
        @(1130, 150, "Physical`noffices"),
        @(430, 390, "Lecturers /`ncourse reps"),
        @(780, 390, "Course`nmaterials"),
        @(1130, 390, "Peers and`nnotice boards")
    )

    foreach ($s in $sources) {
        Draw-Box $g $s[0] $s[1] 260 120 $s[2] "#fff9db" "#b89400" 17
        Draw-Arrow $g 290 445 ($s[0]) ($s[1] + 60) "#6b7280"
    }

    Draw-Box $g 610 675 380 110 "Manual searching`nand repeated inquiries" "#fef2f2" "#b42318" 17
    Draw-Box $g 1100 675 360 110 "Delayed feedback`nNo personal tracking" "#fef2f2" "#b42318" 17
    Draw-Arrow $g 760 510 760 675 "#b42318"
    Draw-Arrow $g 950 730 1100 730 "#b42318"

    Save-Diagram $bmp $g "existing_system_architecture.png"
}

function New-ProposedArchitecture {
    $items = New-Canvas "Architecture of the Proposed Eve System"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 60 175 250 85 "Guest" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 60 310 250 85 "Student" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 60 445 250 85 "Lecturer" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 390 280 270 150 "Flutter Web /`nMobile Client" "#ecfdf3" "#027a48" 18
    Draw-Box $g 750 280 280 150 "FastAPI Backend`nEve Core" "#f5f7fb" "#173f8a" 18
    Draw-Box $g 1110 145 330 95 "Guardrails +`nRole-Based Access" "#fff9db" "#b89400" 16
    Draw-Box $g 1110 285 330 95 "RAG + Curated`nESUI Knowledge" "#eaf2ff" "#173f8a" 16
    Draw-Box $g 1110 425 330 95 "Academic Services +`nStudent Records" "#ecfdf3" "#027a48" 16
    Draw-Box $g 1110 565 330 95 "SQLite Progress +`nPeer-Note Review" "#fef2f2" "#b42318" 16
    Draw-Box $g 750 595 280 90 "Optional OpenAI`nResponses API" "#f4f0ff" "#6941c6" 16

    Draw-Arrow $g 310 220 390 330
    Draw-Arrow $g 310 353 390 355
    Draw-Arrow $g 310 490 390 380
    Draw-Arrow $g 660 355 750 355
    Draw-Arrow $g 1030 355 1110 190
    Draw-Arrow $g 1030 355 1110 333
    Draw-Arrow $g 1030 355 1110 470
    Draw-Arrow $g 1030 355 1110 610
    Draw-Arrow $g 890 430 890 595 "#6941c6"

    Save-Diagram $bmp $g "proposed_system_architecture.png"
}

function New-DataFlowDiagram {
    $items = New-Canvas "Data Flow Diagram"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 70 360 210 100 "User" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 350 360 240 100 "Flutter`nClient" "#ecfdf3" "#027a48" 18
    Draw-Box $g 660 360 240 100 "API`nRequest" "#f5f7fb" "#173f8a" 18
    Draw-Box $g 970 270 260 100 "Guardrail +`nAuthorization" "#fff9db" "#b89400" 16
    Draw-Box $g 970 470 260 100 "Intent +`nAcademic Logic" "#eaf2ff" "#173f8a" 16
    Draw-Box $g 1310 270 230 100 "Knowledge`nRetrieval" "#ecfdf3" "#027a48" 16
    Draw-Box $g 1310 470 230 100 "SQLite +`nRecords" "#fef2f2" "#b42318" 16
    Draw-Box $g 660 650 300 100 "Grounded Eve`nResponse" "#f4f0ff" "#6941c6" 17

    Draw-Arrow $g 280 410 350 410
    Draw-Arrow $g 590 410 660 410
    Draw-Arrow $g 900 410 970 320
    Draw-Arrow $g 900 410 970 520
    Draw-Arrow $g 1230 320 1310 320
    Draw-Arrow $g 1230 520 1310 520
    Draw-Arrow $g 1380 570 960 690 "#6941c6"
    Draw-Arrow $g 790 650 470 460 "#6941c6"
    Draw-Arrow $g 350 390 280 390 "#6941c6"

    Save-Diagram $bmp $g "data_flow_diagram.png"
}

function New-DatabaseErd {
    $items = New-Canvas "Database / Storage Design"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 120 170 430 240 "learning_sessions`n- session_id PK`n- user_id`n- course_code`n- topic`n- created_at`n- completed_at" "#eaf2ff" "#173f8a" 15
    Draw-Box $g 930 170 430 240 "learning_answers`n- id PK`n- session_id FK`n- question`n- answer`n- score`n- feedback" "#ecfdf3" "#027a48" 15
    Draw-Box $g 120 545 430 230 "peer_notes`n- note_id PK`n- user_id`n- course_code`n- content`n- status" "#fff9db" "#b89400" 15
    Draw-Box $g 930 545 430 230 "peer_note_reviews`n- id PK`n- note_id FK`n- reviewer_id`n- action`n- comment" "#fef2f2" "#b42318" 15

    Draw-Arrow $g 550 290 930 290 "#173f8a"
    Draw-Arrow $g 550 660 930 660 "#b42318"

    $font = New-Object System.Drawing.Font "Segoe UI", 18, ([System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush (Color "#1f2937")
    $g.DrawString("one session has many answers", $font, $brush, 585, 245)
    $g.DrawString("one note can receive review actions", $font, $brush, 565, 615)
    $brush.Dispose()
    $font.Dispose()

    Save-Diagram $bmp $g "database_erd.png"
}

function New-DetailedEveArchitecture {
    $items = New-Canvas "Detailed Architecture of the Proposed Eve AI System"
    $bmp = $items[0]
    $g = $items[1]

    $layers = @(
        @(140, 125, 1320, 70, "USER ROLES: Guest | Student | Lecturer | Administrator", "#eaf2ff", "#173f8a"),
        @(140, 225, 1320, 85, "FLUTTER WEB / MOBILE FRONTEND`nLogin, Ask Eve chat, student dashboard, lecturer analytics, admin knowledge tools", "#ecfdf3", "#027a48"),
        @(140, 345, 1320, 80, "FASTAPI BACKEND SERVER`nReceives requests, coordinates system actions, connects frontend to AI and data services", "#f5f7fb", "#173f8a"),
        @(140, 460, 1320, 80, "SECURITY AND ROLE-BASED ACCESS CONTROL`nChecks user role, blocks unauthorized access, detects prompt-injection attempts", "#fff9db", "#b89400"),
        @(140, 575, 1320, 80, "AI PROCESSING LAYER`nIntent detection, Retrieval-Augmented Generation, OpenAI mode, local fallback logic", "#f4f0ff", "#6941c6"),
        @(140, 690, 1320, 80, "ACADEMIC AND KNOWLEDGE SERVICES`nPersonalized learning, progress tracking, guided sessions, lecturer analytics, peer-note review", "#eef4ff", "#175cd3"),
        @(140, 805, 1320, 60, "DATA STORAGE: Controlled ESUI knowledge base | Sample records | SQLite progress database | Peer-note records", "#fef2f2", "#b42318")
    )

    foreach ($layer in $layers) {
        Draw-Box $g $layer[0] $layer[1] $layer[2] $layer[3] $layer[4] $layer[5] $layer[6] 15
    }

    for ($i = 0; $i -lt $layers.Length - 1; $i++) {
        $x = 800
        $y1 = $layers[$i][1] + $layers[$i][3]
        $y2 = $layers[$i + 1][1]
        Draw-Arrow $g $x ($y1 + 5) $x ($y2 - 5) "#173f8a"
    }

    Save-Diagram $bmp $g "proposed_eve_system_architecture_detailed.png"
}

function New-UseCaseDiagram {
    $items = New-Canvas "Use Case Diagram of the Proposed Eve System"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 100 125 240 70 "Guest /`nCandidate" "#eaf2ff" "#173f8a" 14
    Draw-Box $g 465 125 240 70 "Student" "#eaf2ff" "#173f8a" 15
    Draw-Box $g 830 125 240 70 "Lecturer" "#eaf2ff" "#173f8a" 15
    Draw-Box $g 1195 125 240 70 "Administrator" "#eaf2ff" "#173f8a" 14

    Draw-Boundary $g 60 230 1480 620 "EVE AI SYSTEM"

    $columns = @(
        @{
            ActorCenter = @(220, 195)
            Cases = @(
                @(110, 300, "Ask public`nESUI questions"),
                @(110, 415, "View admission`nguidance"),
                @(110, 530, "Estimate admission`nreadiness")
            )
        },
        @{
            ActorCenter = @(585, 195)
            Cases = @(
                @(455, 285, "Ask academic`nquestions"),
                @(455, 390, "View learning`nprogress"),
                @(455, 495, "Start guided`nlearning session"),
                @(455, 600, "Upload notes for`nAsk Eve"),
                @(455, 705, "View study`nrecommendations")
            )
        },
        @{
            ActorCenter = @(950, 195)
            Cases = @(
                @(820, 330, "View course`nanalytics"),
                @(820, 470, "Review peer`nnotes"),
                @(820, 610, "View student`nlearning trends")
            )
        },
        @{
            ActorCenter = @(1315, 195)
            Cases = @(
                @(1185, 330, "Manage knowledge`nbase"),
                @(1185, 470, "Approve or reject`nshared content"),
                @(1185, 610, "View governance`nand audit records")
            )
        }
    )

    foreach ($column in $columns) {
        $actorX = $column.ActorCenter[0]
        $actorY = $column.ActorCenter[1]
        foreach ($case in $column.Cases) {
            Draw-Line $g $actorX $actorY ($case[0] + 130) ($case[1] + 37) "#c0c7d2"
        }
    }

    foreach ($column in $columns) {
        foreach ($case in $column.Cases) {
            Draw-Oval $g $case[0] $case[1] 260 75 $case[2] "#f8fafc" "#173f8a" 12
        }
    }

    Save-Diagram $bmp $g "use_case_diagram.png"
}

New-ExistingArchitecture
New-ProposedArchitecture
New-DataFlowDiagram
New-DatabaseErd
New-DetailedEveArchitecture
New-UseCaseDiagram
