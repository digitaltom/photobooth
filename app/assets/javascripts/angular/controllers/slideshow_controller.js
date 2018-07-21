photoBoothApp.controller('SlideshowCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$routeParams',
  '$rootScope',
  '$interval',
  '$location',
  function ($scope, $http, $uibModal, $log, $routeParams, $rootScope, $interval, $location) {

    $scope.pictureSetId = $routeParams.pictureSetId;
    $log.log('Slideshow for $routeParams.pictureSetId: ' + $routeParams.pictureSetId)

    $scope.loadPictureSet = function () {
      $http({
        method: 'GET',
        url: '/picture_sets/' + $routeParams.pictureSetId
      }).then(function successCallback(response) {
        $scope.picture_set = response.data;
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $interval(function() {
      $routeParams.pictureSetId = $scope.picture_set.next.date
      $scope.pictureSetId = $scope.picture_set.next.date
      $scope.loadPictureSet()
    }, 8000);

    $scope.loadPictureSet()

  }]);
