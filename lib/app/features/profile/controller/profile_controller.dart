import 'package:get/get.dart';
import 'package:the_builder_pros/app/core/base/base_controller.dart';

class ProfileController extends BaseController {
  final tabIndex = 0.obs;
  final rewardsMode = 0.obs;
  final selectedSquad = Rxn<Squad>();
  final followedIds = <String>{'squad-1', 'squad-2'}.obs;
  final search = ''.obs;

  final builder = const BuilderProfile(
    'Jordan Rivers',
    'jordan@example.com',
    'Builder II',
  );
  final balance = '85.00';
  final rewardId = 'BLD-JR-00142';

  final squads = const [
    Squad(
      'squad-1',
      'theBuilderPros Mobile',
      'The mobile companion for following App Squads, viewing work updates, and managing Builder Rewards.',
      'Active',
      0xFFF35A12,
    ),
    Squad(
      'squad-2',
      'Reward Loop',
      'A lightweight rewards app for sending, receiving, and tracking community recognition points.',
      'Active',
      0xFF5B20E5,
    ),
    Squad(
      'squad-3',
      'Classroom Sync',
      'Connects Builder learning activity with Google Classroom and keeps progress in one place.',
      'Forming',
      0xFF0EA5E9,
    ),
    Squad(
      'squad-4',
      'Evidence Studio',
      'Helps Builders collect shipped work and turn it into clear professional evidence.',
      'Active',
      0xFF10B981,
    ),
    Squad(
      'squad-5',
      'Demo Day',
      'A showcase app for discovering Builder projects, releases, and product demonstrations.',
      'Completed',
      0xFFF59E0B,
    ),
  ];

  final workItems = const [
    WorkItem(
      'squad-1',
      'Ship Google Sign-In',
      'Builders can securely access theBuilderPros Mobile with Google.',
      'Done',
      2,
      3,
      'Emerge',
    ),
    WorkItem(
      'squad-1',
      'Build App update feed',
      'Followed Apps show current WIP and shipped work.',
      'WIP',
      2,
      4,
      'Experiment',
    ),
    WorkItem(
      'squad-1',
      'Complete Builder profile home',
      'Builders can see their profile, rewards, and followed Apps.',
      'WIP',
      2,
      4,
      'Experiment',
    ),
    WorkItem(
      'squad-1',
      'Add release notifications',
      'Builders are notified when a followed App publishes a release.',
      'Committed',
      2,
      5,
      'Implement',
    ),
    WorkItem(
      'squad-2',
      'Ship Rewards receive flow',
      'Builders can receive recognition points through an ID or QR code.',
      'Done',
      1,
      2,
      'Listen',
    ),
    WorkItem(
      'squad-2',
      'Build Rewards history',
      'Builders can review recent incoming and outgoing rewards.',
      'WIP',
      1,
      3,
      'Emerge',
    ),
    WorkItem(
      'squad-2',
      'Add transfer confirmation',
      'Builders review recipient and amount before sending rewards.',
      'Committed',
      1,
      4,
      'Experiment',
    ),
    WorkItem(
      'squad-3',
      'Connect Google Classroom',
      'Learning activities can be imported into Classroom Sync.',
      'WIP',
      1,
      1,
      'Download',
    ),
  ];

  void selectTab(int index) {
    tabIndex.value = index;
    selectedSquad.value = null;
  }

  void openSquad(Squad squad) => selectedSquad.value = squad;
  void closeSquad() => selectedSquad.value = null;
  void toggleFollow(String id) =>
      followedIds.contains(id) ? followedIds.remove(id) : followedIds.add(id);
  List<WorkItem> itemsFor(String id) =>
      workItems.where((item) => item.squadId == id).toList();
}

class BuilderProfile {
  const BuilderProfile(this.name, this.email, this.level);
  final String name, email, level;
}

class Squad {
  const Squad(
    this.id,
    this.name,
    this.description,
    this.status,
    this.colorValue,
  );
  final String id, name, description, status;
  final int colorValue;
}

class WorkItem {
  const WorkItem(
    this.squadId,
    this.title,
    this.outcome,
    this.state,
    this.cycle,
    this.week,
    this.weekLabel,
  );
  final String squadId, title, outcome, state, weekLabel;
  final int cycle, week;
}
