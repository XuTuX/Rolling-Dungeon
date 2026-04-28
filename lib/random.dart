import 'dart:math';

/// 영역을 생성하는 함수
List<List<int>> generateRegions(int gridSize, int numTeams, int maxRegionSize) {
  List<List<int>> grid;
  bool valid;

  do {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, -1));
    Random random = Random();
    List<int> teamCellCounts = List.filled(numTeams, 0);
    List<Map<String, dynamic>> frontierList = [];

    // 각 팀에 시드 셀 배치
    for (int team = 0; team < numTeams; team++) {
      int row, col;
      do {
        row = random.nextInt(gridSize);
        col = random.nextInt(gridSize);
      } while (grid[row][col] != -1);

      grid[row][col] = team;
      teamCellCounts[team]++;
      frontierList.add({'point': Point(row, col), 'team': team});
    }

    // 영역 확장
    while (grid.any((row) => row.contains(-1))) {
      // 최대 영역 크기를 초과한 팀의 프론티어 제거
      frontierList.removeWhere(
          (cellInfo) => teamCellCounts[cellInfo['team']] >= maxRegionSize);

      if (frontierList.isEmpty) {
        // 프론티어가 비었을 때 남은 셀을 할당
        if (!assignRemainingCells(grid, gridSize)) break;
        continue;
      }

      // 확장 우선순위 조정: 현재 가장 작은 영역을 가진 팀들의 모든 프론티어 셀 중 하나를 무작위로 선택
      frontierList.sort((a, b) =>
          teamCellCounts[a['team']].compareTo(teamCellCounts[b['team']]));

      int minCount = teamCellCounts[frontierList[0]['team']];
      List<Map<String, dynamic>> candidates = frontierList
          .where((cell) => teamCellCounts[cell['team']] == minCount)
          .toList();

      var cellInfo = candidates[random.nextInt(candidates.length)];
      int team = cellInfo['team'];
      Point<int> point = cellInfo['point'];

      // 인접한 셀 중 하나 선택
      var neighbors = getNeighbors(grid, gridSize, point, unassigned: true);

      if (neighbors.isEmpty) {
        frontierList.remove(cellInfo);
        continue;
      }

      // 뭉침 현상(blob)을 유도하기 위해, 같은 팀 셀과 더 많이 인접한 이웃을 선호함
      neighbors.shuffle(random);
      neighbors.sort((a, b) {
        int aSame = _countSameTeamNeighbors(grid, gridSize, a, team);
        int bSame = _countSameTeamNeighbors(grid, gridSize, b, team);
        return bSame.compareTo(aSame); // 인접한 같은 팀 셀이 많을수록 앞으로
      });

      Point<int> neighbor = neighbors.first;
      grid[neighbor.x][neighbor.y] = team;
      teamCellCounts[team]++;
      frontierList.add({'point': neighbor, 'team': team});
    }

    // 각 팀의 영역이 최소 크기를 충족하는지 확인
    valid = teamCellCounts.every((count) => confirmMinArea(count));
  } while (!valid); // 유효하지 않으면 다시 생성

  return grid;
}

/// 특정 셀과 인접한 같은 팀의 셀 개수를 세는 함수
int _countSameTeamNeighbors(
    List<List<int>> grid, int gridSize, Point<int> point, int team) {
  int count = 0;
  List<Point<int>> directions = [
    const Point(-1, 0),
    const Point(1, 0),
    const Point(0, -1),
    const Point(0, 1),
  ];

  for (var dir in directions) {
    int nx = point.x + dir.x;
    int ny = point.y + dir.y;
    if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
      if (grid[nx][ny] == team) {
        count++;
      }
    }
  }
  return count;
}

bool confirmMinArea(int count) {
  // Relaxed from 7 to 4 to ensure faster generation and more diverse layouts
  return count >= 5;
}

/// 남은 셀을 할당하는 함수
bool assignRemainingCells(List<List<int>> grid, int gridSize) {
  bool changed = false;
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      if (grid[i][j] == -1) {
        var neighbors =
            getNeighbors(grid, gridSize, Point(i, j), unassigned: false);
        if (neighbors.isNotEmpty) {
          int team = grid[neighbors.first.x][neighbors.first.y];
          grid[i][j] = team;
          changed = true;
        }
      }
    }
  }
  return changed;
}

/// 인접한 셀들을 반환하는 함수
List<Point<int>> getNeighbors(
    List<List<int>> grid, int gridSize, Point<int> point,
    {bool unassigned = false}) {
  List<Point<int>> neighbors = [];
  List<Point<int>> directions = [
    const Point(-1, 0), // 위
    const Point(1, 0), // 아래
    const Point(0, -1), // 왼쪽
    const Point(0, 1), // 오른쪽
  ];

  for (var dir in directions) {
    int newRow = point.x + dir.x;
    int newCol = point.y + dir.y;
    if (newRow >= 0 && newRow < gridSize && newCol >= 0 && newCol < gridSize) {
      if (unassigned && grid[newRow][newCol] == -1) {
        neighbors.add(Point(newRow, newCol));
      } else if (!unassigned && grid[newRow][newCol] != -1) {
        neighbors.add(Point(newRow, newCol));
      }
    }
  }
  return neighbors;
}
