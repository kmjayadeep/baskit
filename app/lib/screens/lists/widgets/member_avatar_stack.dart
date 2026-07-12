part of 'list_card_widget.dart';

class _MemberAvatarStack extends StatelessWidget {
  static const int _maxVisibleMembers = 3;
  static const double _avatarSize = 30;
  static const double _overlap = 9;

  final List<ListMember> members;

  const _MemberAvatarStack({required this.members});

  @override
  Widget build(BuildContext context) {
    final visibleMembers = members.take(_maxVisibleMembers).toList();
    final overflowCount = members.length - visibleMembers.length;
    final avatarCount = visibleMembers.length + (overflowCount > 0 ? 1 : 0);

    return Semantics(
      label: _semanticLabel(members),
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: _stackWidth(avatarCount),
          height: _avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < visibleMembers.length; index++)
                Positioned(
                  left: _offsetFor(index),
                  child: _MemberAvatar(member: visibleMembers[index]),
                ),
              if (overflowCount > 0)
                Positioned(
                  left: _offsetFor(visibleMembers.length),
                  child: _OverflowAvatar(count: overflowCount),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _stackWidth(int avatarCount) {
    return avatarCount == 0
        ? _avatarSize
        : _avatarSize + (avatarCount - 1) * (_avatarSize - _overlap);
  }

  double _offsetFor(int index) => index * (_avatarSize - _overlap);

  String _semanticLabel(List<ListMember> members) {
    final names =
        members
            .map((member) => member.displayName.trim())
            .where((name) => name.isNotEmpty && name != 'Unknown User')
            .toList();

    if (names.isEmpty) {
      return members.length == 1
          ? 'Shared with 1 person'
          : 'Shared with ${members.length} people';
    }

    final listedNames = names.take(_maxVisibleMembers).toList();
    final others = members.length - listedNames.length;
    return _sharedWithLabel(listedNames, others);
  }

  String _sharedWithLabel(List<String> names, int others) {
    if (names.length == 1) {
      return others > 0
          ? 'Shared with ${names.first} and $others ${_personNoun(others)}'
          : 'Shared with ${names.first}';
    }

    if (names.length == 2) {
      return others > 0
          ? 'Shared with ${names[0]}, ${names[1]}, and $others ${_personNoun(others)}'
          : 'Shared with ${names[0]} and ${names[1]}';
    }

    if (others > 0) {
      return 'Shared with ${names.join(', ')}, and $others ${_personNoun(others)}';
    }

    final leadingNames = names.take(names.length - 1).join(', ');
    return 'Shared with $leadingNames, and ${names.last}';
  }

  String _personNoun(int count) => count == 1 ? 'other' : 'others';
}

class _MemberAvatar extends StatelessWidget {
  final ListMember member;

  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(member.displayName);
    final avatarUrl = _validAvatarUrl(member.avatarUrl);

    return _AvatarFrame(
      child:
          avatarUrl == null
              ? _AvatarFallback(initials: initials)
              : ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _AvatarFallback(initials: initials);
                  },
                ),
              ),
    );
  }

  String? _validAvatarUrl(String? avatarUrl) {
    final trimmedUrl = avatarUrl?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }

    return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http')
        ? trimmedUrl
        : null;
  }

  String _initialsFor(String displayName) {
    final parts =
        displayName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();

    if (parts.isEmpty || displayName.trim() == 'Unknown User') {
      return '';
    }

    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _OverflowAvatar extends StatelessWidget {
  final int count;

  const _OverflowAvatar({required this.count});

  @override
  Widget build(BuildContext context) {
    return _AvatarFrame(
      backgroundColor: AppColors.primaryGreen,
      child: Center(
        child: Text(
          '+$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AvatarFrame extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const _AvatarFrame({required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _MemberAvatarStack._avatarSize,
      height: _MemberAvatarStack._avatarSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) {
      return const Center(
        child: Icon(Icons.person, size: 16, color: AppColors.primaryGreen),
      );
    }

    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
