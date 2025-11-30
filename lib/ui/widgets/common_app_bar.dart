import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/cart_provider.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final List<Widget>? additionalActions;
  final bool showCartBadge;
  final bool showSearchButton;
  final bool showFavoritesButton;

  const CommonAppBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.additionalActions,
    this.showCartBadge = true,
    this.showSearchButton = true,
    this.showFavoritesButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cart = context.watch<CartProvider>();
    final cartItemsCount = cart.items.length;

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      elevation: 0,
      actions: [
        if (showSearchButton)
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'بحث',
          ),
        if (showFavoritesButton)
          IconButton(
            onPressed: () => context.push('/favorites'),
            icon: const Icon(Icons.favorite_border_rounded),
            tooltip: 'المفضلة',
          ),
        if (showCartBadge)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => context.push('/cart'),
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'السلة',
              ),
              if (cartItemsCount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartItemsCount > 99 ? '99+' : '$cartItemsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }
}

